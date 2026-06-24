@echo off
echo ========================================
echo Deploying Debug Version to Vercel
echo ========================================
echo.

cd website

echo Step 1: Adding files...
git add .

echo Step 2: Committing changes...
git commit -m "Add debugging tools for Vercel issue"

echo Step 3: Pushing to repository...
git push

echo.
echo ========================================
echo Deployment Started!
echo ========================================
echo.
echo Wait 2-3 minutes for Vercel to deploy.
echo.
echo Then open your site with debug mode:
echo https://your-site.vercel.app/?debug=true
echo.
echo Check the debug panel at bottom-right corner.
echo.
pause
