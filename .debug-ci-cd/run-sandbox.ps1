# .debug-ci-cd/run-sandbox.ps1

Write-Host "=> Preparing isolated sandbox for Godot CI debugging (Windows)..." -ForegroundColor Cyan

# 1. Najdeme kořen projektu (o úroveň výš než tento skript)
$ProjectRoot = Resolve-Path "$PSScriptRoot\.."

# 2. Vytvoříme dočasnou složku v systému
$TempDir = Join-Path $env:TEMP ("godot-sandbox-" + [Guid]::NewGuid().ToString().Substring(0,8))
New-Item -ItemType Directory -Path $TempDir | Out-Null

Write-Host "=> Copying project to sandbox: $TempDir" -ForegroundColor Yellow

# 3. Vyklonujeme projekt do dočasné složky (bez .git a .godot)
# Robocopy je ve Windows nejlepší náhrada za rsync
robocopy $ProjectRoot $TempDir /S /XD .git .godot /R:0 /W:0 /NFL /NDL /NJH /NJS

Write-Host "=> Starting Docker (barichello/godot-ci:mono-4.6.1)..." -ForegroundColor Cyan
Write-Host "=> Type 'exit' to destroy sandbox and return." -ForegroundColor Gray

# 4. Spustíme izolovaný kontejner (interaktivně)
# Používáme přesně tu verzi 4.6.1, kterou má Ivan
docker run -it --rm `
    -v "${TempDir}:/workspace" `
    -w /workspace `
    barichello/godot-ci:mono-4.6.1 bash

# 5. Úklid po ukončení
Write-Host "=> Destroying sandbox..." -ForegroundColor Yellow
Remove-Item -Path $TempDir -Recurse -Force

Write-Host "=> Done. Your local files are untouched." -ForegroundColor Green
Pause
