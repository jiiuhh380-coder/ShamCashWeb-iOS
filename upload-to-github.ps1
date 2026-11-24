param(
    [string]$RepoName = "ShamCashWeb-iOS",
    [ValidateSet('private', 'public')][string]$Visibility = 'private',
    [switch]$NoInstall
)

$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ProjectDir

function Ensure-Tool {
    param([string]$Name, [string]$PackageId)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return }
    if ($NoInstall -or -not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "$Name is not installed. Install it manually, then re-run this script."
    }
    Write-Host "Installing $PackageId ..." -ForegroundColor Yellow
    winget install --id $PackageId -e --accept-source-agreements --accept-package-agreements
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name was installed but is not on PATH. Restart PowerShell and re-run."
    }
}

Ensure-Tool -Name git -PackageId Git.Git
Ensure-Tool -Name gh -PackageId GitHub.cli

$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub login is required. A browser window will open." -ForegroundColor Yellow
    gh auth login --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { throw "GitHub login failed." }
}

$owner = gh api user --jq .login
if ($LASTEXITCODE -ne 0 -or -not $owner) { throw "Could not read GitHub username." }
$userId = gh api user --jq .id

if (-not (Test-Path .git)) {
    git init
    git symbolic-ref HEAD refs/heads/main
}

git config user.name $owner
git config user.email "$userId+$owner@users.noreply.github.com"

git add -A
if (git status --porcelain) {
    git commit -m "Add ShamCash iOS web wrapper project"
    if ($LASTEXITCODE -ne 0) { throw "Git commit failed." }
}

$previousPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$existing = gh repo view "$owner/$RepoName" 2>$null
$viewExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousPreference

if ($viewExitCode -eq 0) {
    Write-Host "Repository already exists: https://github.com/$owner/$RepoName" -ForegroundColor Cyan
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$owner/$RepoName.git"
    git push -u origin main
} else {
    gh repo create $RepoName --$Visibility --source=. --remote=origin --push
    if ($LASTEXITCODE -ne 0) { throw "Repository creation or push failed." }
}

Write-Host ""
Write-Host "Done. Next steps:" -ForegroundColor Green
Write-Host "  1. Open https://github.com/$owner/$RepoName/actions"
Write-Host "  2. Run Workflow: 'Build unsigned IPA'"
Write-Host "  3. Download ShamCashWeb-unsigned-ipa from the finished run"
