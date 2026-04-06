# Nastavení cesty - automaticky vezme složku, kde je tento skript
$PROJECT_PATH = Get-Location

Write-Host "--- STARTUJU DOCKER SANDBOX ---" -ForegroundColor Cyan

# PŘÍKAZ PRO DOCKER:
# -v propojí tvou Windows složku s vnitřkem Dockeru
# barichello/godot-ci:4.2.1 je obraz systému, kde už je Godot nainstalovaný
docker run --rm -v "${PROJECT_PATH}:/project" -w /project barichello/godot-ci:4.2.1 bash -c "
    echo 'Čistím mezipaměť...'
    rm -rf src/.godot
    echo 'Spouštím Godot test (bez okna)...'
    godot --headless --path src --editor --quit --verbose
"

Write-Host "--- TEST DOKONČEN ---" -ForegroundColor Cyan
Pause
