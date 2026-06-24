# Run this script as Administrator to allow port 3000 through Windows Firewall
# Right-click PowerShell and select "Run as Administrator"

Write-Host "Adding Windows Firewall rule for Node.js backend (port 3000)..." -ForegroundColor Yellow

# Remove existing rule if it exists
Remove-NetFirewallRule -DisplayName "Node.js Backend Port 3000" -ErrorAction SilentlyContinue

# Add new inbound rule
New-NetFirewallRule `
    -DisplayName "Node.js Backend Port 3000" `
    -Direction Inbound `
    -LocalPort 3000 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Enabled True

Write-Host "✅ Firewall rule added successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Now restart your Flutter app and the backend should be accessible." -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
