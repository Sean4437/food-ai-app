$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root "backend"
$frontend = Join-Path $root "frontend"

Start-Process powershell -ArgumentList @(
  "-NoExit",
  "-Command",
  "cd '$backend'; .\.venv\Scripts\Activate.ps1; uvicorn app:app --reload --host 0.0.0.0 --port 8000"
)

Start-Process powershell -ArgumentList @(
  "-NoExit",
  "-Command",
  "cd '$frontend'; flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8081"
)
