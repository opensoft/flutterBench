$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$shellScript = Join-Path $scriptRoot "scripts/start-monster.sh"

Write-Host "Launching layered Flutter bench startup via $shellScript" -ForegroundColor Cyan

if ($env:WSL_DISTRO_NAME) {
    & bash $shellScript
    exit $LASTEXITCODE
}

try {
    $linuxScript = (& wsl wslpath -a $shellScript).Trim()
} catch {
    Write-Host "❌ Error: Could not resolve WSL path for $shellScript" -ForegroundColor Red
    exit 1
}

& wsl bash -lc "bash '$linuxScript'"
exit $LASTEXITCODE
