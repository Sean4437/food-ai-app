param(
  [string]$Message = "Update files"
)

$repo = "C:\Users\USER\Documents\AI\food-ai-app"
$git = "C:\Program Files\Git\bin\git.exe"

if (!(Test-Path $git)) {
  $git = "C:\Program Files\Git\cmd\git.exe"
}
if (!(Test-Path $git)) {
  $git = "git.exe"
}

$filesPath = Join-Path $repo "git_files.txt"
if (!(Test-Path $filesPath)) {
  Write-Host "Missing git_files.txt" -ForegroundColor Red
  exit 1
}

$files = Get-Content $filesPath | Where-Object { $_ -and $_.Trim() -ne "" }
if ($files.Count -eq 0) {
  Write-Host "git_files.txt is empty" -ForegroundColor Yellow
  exit 0
}

Set-Location $repo

& $git add -- $files
& $git commit -m $Message
& $git push
