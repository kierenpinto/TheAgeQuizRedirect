using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

function Get-QuizURL(){
    $ErrorActionPreference = 'Break'

    $baseURL = "https://www.smh.com.au/topic/quizzes-1qx"    
    
    $allQuizListings = Invoke-WebRequest $baseURL
    
    $superQuizTuesday = $allQuizListings.Links | Where-Object -Property href -Match "superquiz" | Where-Object -Property tabindex -eq -1
    
    if ($null -eq $superQuizTuesday)
    {
        Write-Host "Something went wrong, please figure out why superquiz tuesday isn't here"
    }
    
    $superQuizTuesdayHref = $baseURL + $superQuizTuesday[0].href
    
    
    $quizPageWithFrame = Invoke-WebRequest $superQuizTuesdayHref
    
    $quizFrameURL = ($quizPageWithFrame | select-string -AllMatches "https://www.smh.com.au/interactive/modules/super-quiz/index.html[^`"]*").Matches
    
    $urls = $quizFrameURL | ForEach-Object { $_.Value }

    return $urls[1]
}

function Get-QuizURLV2(){
    $ErrorActionPreference = 'Stop'

    $baseURL = "https://www.smh.com.au/topic/quizzes-1qx"

    # Get the quiz listings page
    $allQuizListings = Invoke-WebRequest $baseURL

    # Find the superquiz-tuesday link
    $superQuizTuesday = $allQuizListings.Links | Where-Object -Property href -Match "superquiz-tuesday" | Where-Object -Property tabindex -eq -1

    if ($null -eq $superQuizTuesday)
    {
        Write-Host "Something went wrong, please figure out why superquiz tuesday isn't here"
        exit 1
    }

    # Fix: Check if href is relative or absolute
    $href = $superQuizTuesday[0].href
    if ($href -notmatch '^https?://') {
        # If relative, prepend the base domain
        $superQuizTuesdayHref = "https://www.smh.com.au" + $href
    } else {
        # If absolute, use as-is
        $superQuizTuesdayHref = $href
    }

    Write-Host "This weeks quiz article URL: $superQuizTuesdayHref"

    # Get the quiz article page
    $quizPageWithFrame = Invoke-WebRequest $superQuizTuesdayHref

    # Current quizzes use a Riddle embed. Prefer its data attribute, then fall back
    # to extracting the ID from the iframe URL.
    $riddleIdMatch = [regex]::Match($quizPageWithFrame.Content, 'data-rid-id="(?<Id>[A-Za-z0-9_-]+)"')

    if (-not $riddleIdMatch.Success)
    {
        $riddleIdMatch = [regex]::Match($quizPageWithFrame.Content, 'https://www\.riddle\.com/(?:embed/a|view)/(?<Id>[A-Za-z0-9_-]+)')
    }

    if ($riddleIdMatch.Success)
    {
        $quizUrl = 'https://www.riddle.com/view/{0}' -f $riddleIdMatch.Groups['Id'].Value
        Write-Host "`nThis week's quiz URL: $quizUrl"
        return $quizURL
        # exit 0
    }

    # Older articles use the original SMH interactive quiz frame.
    $legacyQuizMatch = [regex]::Match($quizPageWithFrame.Content, 'https://www\.smh\.com\.au/interactive/modules/super-quiz/index\.html[^"''<>]*')

    if ($legacyQuizMatch.Success)
    {
        $quizUrl = [System.Net.WebUtility]::HtmlDecode($legacyQuizMatch.Value)
        Write-Host "`nThis week's quiz URL: $quizUrl"
        return $quizURL
        # exit 0
    }

    Write-Error "No quiz URL was found in the article. The page structure may have changed."
 
}

$quizURL = Get-QuizURLV2

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::Found
    Headers = @{ "Location" = $quizURL }
})
exit 0

<#
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
#>
