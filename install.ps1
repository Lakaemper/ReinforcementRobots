# Sets up the Python environment for the BipedalWalker RL project (PYTHON/).
# Safe to re-run: skips venv creation if it already exists, and pip install
# is idempotent. Run from anywhere - paths are resolved relative to this script.

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonDir  = Join-Path $repoRoot "PYTHON"
$venvDir    = Join-Path $pythonDir "venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
$requirements = Join-Path $pythonDir "requirements.txt"

Write-Host "== ReinforcementRobots setup ==" -ForegroundColor Cyan

if (-not (Test-Path $requirements)) {
    Write-Host "ERROR: requirements.txt not found at $requirements" -ForegroundColor Red
    exit 1
}

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "ERROR: 'python' not found on PATH. Install Python 3.13+ first, then re-run this script." -ForegroundColor Red
    exit 1
}

$pyVersion = & python --version
Write-Host "Found system Python: $pyVersion"
if ($pyVersion -notmatch "3\.13") {
    Write-Host "WARNING: this project's requirements.txt was pinned against Python 3.13 wheels (torch, box2d, pygame-ce)." -ForegroundColor Yellow
    Write-Host "         Your system Python is '$pyVersion' - pip install below may fail to find matching wheels." -ForegroundColor Yellow
}

if (Test-Path $venvPython) {
    Write-Host "venv already exists at $venvDir - skipping creation."
} else {
    Write-Host "Creating virtual environment at $venvDir ..."
    python -m venv $venvDir
    if (-not (Test-Path $venvPython)) {
        Write-Host "ERROR: venv creation failed." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Upgrading pip..."
& $venvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: pip upgrade failed." -ForegroundColor Red
    exit 1
}

Write-Host "Installing dependencies from requirements.txt..."
& $venvPython -m pip install -r $requirements
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: dependency install failed." -ForegroundColor Red
    Write-Host "       If box2d/torch/pygame-ce wheels weren't found, your Python version likely doesn't match what requirements.txt was built against." -ForegroundColor Red
    exit 1
}

Write-Host "Running headless smoke test (BipedalWalker-v3 reset/step, no render)..."
$smokeTestScript = Join-Path $env:TEMP "rr_smoke_test.py"
@"
import gymnasium as gym
env = gym.make('BipedalWalker-v3')
obs, info = env.reset()
for _ in range(20):
    obs, reward, terminated, truncated, info = env.step(env.action_space.sample())
env.close()
print('Smoke test OK - obs shape:', obs.shape)
"@ | Set-Content -Path $smokeTestScript -Encoding utf8

& $venvPython $smokeTestScript
$smokeExit = $LASTEXITCODE
Remove-Item $smokeTestScript -ErrorAction SilentlyContinue

if ($smokeExit -ne 0) {
    Write-Host "ERROR: smoke test failed - environment did not install correctly." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
Write-Host "Activate the venv:  $venvDir\Scripts\Activate.ps1"
Write-Host "Or run scripts directly, e.g.:  $venvPython PYTHON\hello_render.py"
