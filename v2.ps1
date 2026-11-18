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

Start-Process $urls[1] # Open the 2nd URL in browser