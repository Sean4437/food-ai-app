param(
  [Parameter(Mandatory = $true)]
  [string]$Repo,

  [int]$Count = 5,

  [string]$Workflow = ""
)

$token = $env:GITHUB_TOKEN
$tokenPath = Join-Path $PSScriptRoot ".github_token"
if ((-not $token -or $token.Trim() -eq "") -and (Test-Path $tokenPath)) {
  $token = (Get-Content -Path $tokenPath -Raw).Trim()
}

if (-not $token -or $token.Trim() -eq "") {
  Write-Host "Missing GitHub token." -ForegroundColor Red
  Write-Host "Set env var or create tools/.github_token" -ForegroundColor Yellow
  Write-Host "Example: `"$tokenPath`" contains the token only."
  exit 1
}

if (-not ($Repo -match "^[^/]+/[^/]+$")) {
  Write-Host "Repo must be in 'owner/name' format." -ForegroundColor Red
  exit 1
}

$headers = @{
  Authorization = "Bearer $token"
  Accept        = "application/vnd.github+json"
}

$base = "https://api.github.com/repos/$Repo/actions"

function Invoke-GhGet([string]$Url) {
  return Invoke-RestMethod -Method Get -Uri $Url -Headers $headers
}

$perPage = 50
$runsUrl = "$base/runs?per_page=$perPage"
if ($Workflow.Trim() -ne "") {
  $runsUrl = "$base/workflows/$Workflow/runs?per_page=$perPage"
}

$runs = Invoke-GhGet $runsUrl
if (-not $runs.workflow_runs) {
  Write-Host "No workflow runs found." -ForegroundColor Yellow
  exit 0
}

$failed = @()
foreach ($run in $runs.workflow_runs) {
  if ($run.status -ne "completed") { continue }
  if ($run.conclusion -eq "success") { continue }
  $failed += $run
  if ($failed.Count -ge $Count) { break }
}

if ($failed.Count -eq 0) {
  Write-Host "No failed runs found." -ForegroundColor Green
  exit 0
}

foreach ($run in $failed) {
  Write-Host "---------------------------"
  Write-Host "Name:        $($run.name)"
  Write-Host "Conclusion:  $($run.conclusion)"
  Write-Host "Created At:  $($run.created_at)"
  Write-Host "URL:         $($run.html_url)"

  $jobsUrl = "$base/runs/$($run.id)/jobs?per_page=100"
  try {
    $jobs = Invoke-GhGet $jobsUrl
    $failedStep = $null
    foreach ($job in $jobs.jobs) {
      if ($job.conclusion -eq "success") { continue }
      if ($job.steps) {
        $failedStep = $job.steps | Where-Object { $_.conclusion -ne "success" -and $_.conclusion -ne $null } | Select-Object -First 1
        if ($failedStep) {
          Write-Host "Job:         $($job.name)"
          Write-Host "Step:        $($failedStep.name)"
          Write-Host "Step Result: $($failedStep.conclusion)"
          break
        }
      }
      Write-Host "Job:         $($job.name)"
      Write-Host "Job Result:  $($job.conclusion)"
      break
    }
  } catch {
    Write-Host "Failed to fetch jobs for run $($run.id)" -ForegroundColor Yellow
  }
}
