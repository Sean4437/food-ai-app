Param(
  [switch]$Stop,
  [switch]$Start,
  [switch]$Restart,
  [switch]$Tunnel
)

$backend = Split-Path -Parent $MyInvocation.MyCommand.Path

function Stop-Backend {
  Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*uvicorn*" -or $_.ProcessName -like "python*" } |
    ForEach-Object {
      try { $_.CloseMainWindow() | Out-Null } catch {}
      try { Stop-Process -Id $_.Id -Force } catch {}
    }
}

function Start-Backend {
  Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$backend'; .\.venv\Scripts\Activate.ps1; uvicorn app:app --reload --host 0.0.0.0 --port 8000"
  )
}

function Start-Tunnel {
  if ($Tunnel) {
    Start-Process powershell -ArgumentList @(
      "-NoExit",
      "-Command",
      "cloudflared tunnel --url http://127.0.0.1:8000"
    )
  }
}

if ($Restart) {
  Stop-Backend
  Start-Backend
  Start-Tunnel
  exit 0
}

if ($Stop) { Stop-Backend }
if ($Start) { Start-Backend; Start-Tunnel }
