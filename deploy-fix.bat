@echo off
echo ========================================
echo Deploying Mixed Content Fix
echo ========================================
echo.

cd website

echo Step 1: Adding files...
git add .

echo Step 2: Committing changes...
git commit -m "Fix mixed content issue with Vercel serverless proxy"

echo Step 3: Pushing to repository...
git push

echo.
echo ========================================
echo Deployment Started!
echo ========================================
echo.
echo The fix includes:
echo - Vercel serverless functions as proxy
echo - Updated Hero component
echo - Automatic environment detection
echo.
echo Wait 2-3 minutes for Vercel to deploy.
echo.
echo Then test your site:
echo https://your-site.vercel.app
echo.
echo Should now show: "Download App (104.47 MB)"
echo.
echo No more mixed content errors!
echo.
pause
