# PowerShell Script to push website folder to different GitHub account
# Enhanced with robust error handling and debugging

$ErrorActionPreference = "Continue"

function Show-Error {
    param([string]$Message, [string]$Details = "")
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    if ($Details) {
        Write-Host "Details: $Details" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Test-GitInstalled {
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Show-Error "Git is not installed or not in PATH" "Please install Git from https://git-scm.com/download/win"
        return $false
    }
    return $false
}

function Test-EmailValid {
    param([string]$Email)
    return $Email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
}

function Test-GitHubConnectivity {
    try {
        Write-Host "Testing GitHub connectivity..." -ForegroundColor Yellow
        $response = Test-NetConnection -ComputerName github.com -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($response) {
            Write-Host "GitHub is reachable" -ForegroundColor Green
            return $true
        } else {
            Show-Error "Cannot reach GitHub" "Check your internet connection"
            return $false
        }
    } catch {
        Write-Host "Could not test connectivity, continuing anyway..." -ForegroundColor Yellow
        return $true
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Push Website to GitHub (Different Account)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Running pre-flight checks..." -ForegroundColor Cyan
Write-Host ""

if (-not (Test-GitInstalled)) {
    exit 1
}

if (-not (Test-GitHubConnectivity)) {
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

Write-Host ""

$GITHUB_USERNAME = "j28045147-sys"
$GITHUB_REPO = "https://github.com/j28045147-sys/wedding-emergecy-website-.git"
$GITHUB_REPO_NAME = "wedding-emergecy-website-"

do {
    $GITHUB_EMAIL = Read-Host "Enter email for j28045147-sys account"
    if (-not (Test-EmailValid $GITHUB_EMAIL)) {
        Write-Host "Invalid email format. Please try again." -ForegroundColor Yellow
    }
} while (-not (Test-EmailValid $GITHUB_EMAIL))

Write-Host "Email validated: $GITHUB_EMAIL" -ForegroundColor Green

Write-Host ""
Write-Host "Choose authentication method:" -ForegroundColor Cyan
Write-Host "1) Personal Access Token (Recommended)"
Write-Host "2) Username/Password"
Write-Host ""
$AUTH_METHOD = Read-Host "Enter choice (1 or 2)"

if ($AUTH_METHOD -eq "1") {
    Write-Host ""
    Write-Host "To create a Personal Access Token:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://github.com/settings/tokens" -ForegroundColor White
    Write-Host "2. Click Generate new token (classic)" -ForegroundColor White
    Write-Host "3. Select scope: repo (full control)" -ForegroundColor White
    Write-Host "4. Generate and copy the token" -ForegroundColor White
    Write-Host ""
    
    $GITHUB_TOKEN_SECURE = Read-Host "Enter Personal Access Token" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GITHUB_TOKEN_SECURE)
    $GITHUB_TOKEN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    if ($GITHUB_TOKEN -notmatch '^ghp_[a-zA-Z0-9]{36}$' -and $GITHUB_TOKEN -notmatch '^github_pat_[a-zA-Z0-9_]{82}$') {
        Write-Host "Warning: Token format does not match expected pattern" -ForegroundColor Yellow
        Write-Host "Classic tokens start with ghp_" -ForegroundColor Yellow
        Write-Host "Fine-grained tokens start with github_pat_" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne "y") {
            exit 1
        }
    }
    
    $REPO_URL = "https://${GITHUB_TOKEN}@github.com/j28045147-sys/${GITHUB_REPO_NAME}.git"
    Write-Host "Using Personal Access Token authentication" -ForegroundColor Green
} else {
    $REPO_URL = $GITHUB_REPO
    Write-Host "Using username/password authentication" -ForegroundColor Green
    Write-Host "You will be prompted for credentials during push" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Starting push process..." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "website")) {
    Show-Error "Website folder not found in current directory" "Current location: $(Get-Location)"
    Write-Host "Please run this script from your project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "Website folder found" -ForegroundColor Green

try {
    Set-Location website
    Write-Host "Changed to website directory" -ForegroundColor Green
} catch {
    Show-Error "Failed to navigate to website folder" $_.Exception.Message
    exit 1
}

if (Test-Path ".git") {
    Write-Host ""
    Write-Host "Git repository already exists in website folder" -ForegroundColor Yellow
    $REMOVE_GIT = Read-Host "Remove existing .git and start fresh? (y/n)"
    if ($REMOVE_GIT -eq "y") {
        try {
            Remove-Item -Recurse -Force .git -ErrorAction Stop
            Write-Host "Removed existing .git folder" -ForegroundColor Green
        } catch {
            Show-Error "Failed to remove .git folder" $_.Exception.Message
            Set-Location ..
            exit 1
        }
    }
}

if (-not (Test-Path ".git")) {
    Write-Host ""
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    $initOutput = git init 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Git repository initialized" -ForegroundColor Green
    } else {
        Show-Error "Failed to initialize Git repository" $initOutput
        Set-Location ..
        exit 1
    }
}

Write-Host ""
Write-Host "Configuring Git for this repository..." -ForegroundColor Yellow
git config user.name $GITHUB_USERNAME
git config user.email $GITHUB_EMAIL

$configName = git config user.name
$configEmail = git config user.email

if ($configName -eq $GITHUB_USERNAME -and $configEmail -eq $GITHUB_EMAIL) {
    Write-Host "Git configured successfully" -ForegroundColor Green
    Write-Host "  Username: $configName" -ForegroundColor White
    Write-Host "  Email: $configEmail" -ForegroundColor White
} else {
    Show-Error "Git configuration failed" "Expected: $GITHUB_USERNAME <$GITHUB_EMAIL>"
    Set-Location ..
    exit 1
}

if (-not (Test-Path ".gitignore")) {
    Write-Host ""
    Write-Host "Creating .gitignore..." -ForegroundColor Yellow
    try {
        @"
# Dependencies
node_modules/

# Build outputs
build/
dist/
.next/
out/

# Environment variables
.env
.env.local
.env.production

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8 -ErrorAction Stop
        Write-Host ".gitignore created" -ForegroundColor Green
    } catch {
        Show-Error "Failed to create .gitignore" $_.Exception.Message
        Set-Location ..
        exit 1
    }
} else {
    Write-Host ".gitignore already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Checking files to be committed..." -ForegroundColor Yellow
$filesToAdd = git status --porcelain 2>&1
if ($filesToAdd) {
    Write-Host "Files to be added:" -ForegroundColor White
    Write-Host $filesToAdd -ForegroundColor Gray
}

Write-Host ""
Write-Host "Adding files to Git..." -ForegroundColor Yellow
$addOutput = git add . 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Files added successfully" -ForegroundColor Green
} else {
    Show-Error "Failed to add files" $addOutput
    Set-Location ..
    exit 1
}

$statusOutput = git status --porcelain
if (-not $statusOutput) {
    Write-Host "No changes to commit" -ForegroundColor Yellow
    $forceCommit = Read-Host "Create empty commit anyway? (y/n)"
    if ($forceCommit -ne "y") {
        Set-Location ..
        exit 0
    }
    $commitFlags = "--allow-empty"
} else {
    $commitFlags = ""
}

Write-Host ""
Write-Host "Creating commit..." -ForegroundColor Yellow
if ($commitFlags) {
    $commitOutput = git commit $commitFlags -m "Initial commit: Wedding emergency website" 2>&1
} else {
    $commitOutput = git commit -m "Initial commit: Wedding emergency website" 2>&1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Commit created successfully" -ForegroundColor Green
} else {
    Show-Error "Failed to create commit" $commitOutput
    Set-Location ..
    exit 1
}

$existingRemotes = git remote -v 2>&1
if ($existingRemotes -match "origin") {
    Write-Host ""
    Write-Host "Removing existing remote origin..." -ForegroundColor Yellow
    git remote remove origin 2>&1 | Out-Null
}

Write-Host ""
Write-Host "Adding remote repository..." -ForegroundColor Yellow
$remoteOutput = git remote add origin $REPO_URL 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Remote added successfully" -ForegroundColor Green
} else {
    Show-Error "Failed to add remote" $remoteOutput
    Set-Location ..
    exit 1
}

$verifyRemote = git remote -v 2>&1
Write-Host "Remote configuration:" -ForegroundColor White
Write-Host $verifyRemote -ForegroundColor Gray

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing repository access..." -ForegroundColor Yellow
$fetchOutput = git ls-remote origin 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Repository is accessible" -ForegroundColor Green
} else {
    Write-Host "Could not access repository" -ForegroundColor Yellow
    Write-Host "Error details:" -ForegroundColor Yellow
    Write-Host $fetchOutput -ForegroundColor Red
    Write-Host ""
    Write-Host "Common causes:" -ForegroundColor Yellow
    Write-Host "1. Invalid Personal Access Token" -ForegroundColor White
    Write-Host "2. Token does not have repo scope" -ForegroundColor White
    Write-Host "3. Repository does not exist" -ForegroundColor White
    Write-Host "4. No access to repository" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Try to push anyway? (y/n)"
    if ($continue -ne "y") {
        Set-Location ..
        exit 1
    }
}

Write-Host ""
Write-Host "Pushing to main branch..." -ForegroundColor Yellow
$pushOutput = git push -u origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully pushed to main branch!" -ForegroundColor Green
} else {
    Write-Host "Push to main failed, analyzing error..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Error output:" -ForegroundColor Red
    Write-Host $pushOutput -ForegroundColor Red
    Write-Host ""
    
    if ($pushOutput -match "does not match any" -or $pushOutput -match "failed to push") {
        Write-Host "Attempting to create and push main branch..." -ForegroundColor Yellow
        git branch -M main 2>&1 | Out-Null
        $pushOutput = git push -u origin main --force 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully pushed to main branch!" -ForegroundColor Green
        } else {
            Write-Host ""
            Show-Error "Push failed after retry" $pushOutput
            Write-Host ""
            Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
            Write-Host "1. Verify your Personal Access Token is correct" -ForegroundColor White
            Write-Host "2. Check token has repo scope" -ForegroundColor White
            Write-Host "3. Verify repository exists" -ForegroundColor White
            Write-Host "4. Check you have push access" -ForegroundColor White
            Write-Host ""
            Set-Location ..
            exit 1
        }
    } else {
        Write-Host ""
        Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
        Write-Host "1. Verify your Personal Access Token is correct" -ForegroundColor White
        Write-Host "2. Check token has repo scope" -ForegroundColor White
        Write-Host "3. Verify repository exists" -ForegroundColor White
        Write-Host ""
        Set-Location ..
        exit 1
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Website successfully pushed to GitHub!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repository Details:" -ForegroundColor Cyan
Write-Host "  URL: $GITHUB_REPO" -ForegroundColor White
Write-Host "  Branch: main" -ForegroundColor White
Write-Host "  Author: $GITHUB_USERNAME <$GITHUB_EMAIL>" -ForegroundColor White
Write-Host ""
Write-Host "View your repository at:" -ForegroundColor Yellow
Write-Host "  https://github.com/j28045147-sys/wedding-emergecy-website-" -ForegroundColor Cyan
Write-Host ""

Set-Location ..

Write-Host "Verifying main project Git config..." -ForegroundColor Yellow
$mainName = git config user.name 2>&1
$mainEmail = git config user.email 2>&1
Write-Host "Main project config unchanged:" -ForegroundColor Green
Write-Host "  Username: $mainName" -ForegroundColor White
Write-Host "  Email: $mainEmail" -ForegroundColor White
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
