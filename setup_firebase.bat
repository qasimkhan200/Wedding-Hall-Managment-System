@echo off
echo ========================================
echo Firebase Setup for Let's Organize It
echo ========================================
echo.
echo This will configure Firebase for your app
echo Project: orginize-app
echo Package: com.example.orginizeapp
echo.
echo Press any key to continue...
pause > nul

echo.
echo Running FlutterFire CLI configuration...
echo.

dart pub global run flutterfire_cli:flutterfire configure --project=orginize-app

echo.
echo ========================================
echo Configuration Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Check that lib/firebase_options.dart was created
echo 2. Enable Email/Password auth in Firebase Console
echo 3. Create Firestore database in Firebase Console
echo 4. Deploy security rules (see FIREBASE_CLI_SETUP.md)
echo.
echo Press any key to exit...
pause > nul
