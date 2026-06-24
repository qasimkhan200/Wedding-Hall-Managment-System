# 🔄 Rebuild App to Use AWS Backend

## ❌ Problem

Your app is still using the old local IP: `http://192.168.43.104:3000`

This is because the app was built **before** we updated the `.env` file with the AWS backend URL.

---

## ✅ Solution: Rebuild the App

The `.env` file is already updated with the correct AWS URL: `http://51.20.89.101`

You just need to rebuild the app to pick up this change.

---

## 🚀 Rebuild Steps

### Option 1: Quick Rebuild (Recommended)

```powershell
cd "D:\projects\orginize app\orginizeapp"
flutter clean
flutter pub get
flutter build apk --release
```

**Time**: ~3-5 minutes

---

### Option 2: Run in Debug Mode First (To Test)

If you want to test quickly without building release APK:

```powershell
cd "D:\projects\orginize app\orginizeapp"
flutter clean
flutter pub get
flutter run
```

This will:
- Clean old build
- Get dependencies
- Run app in debug mode
- You can see logs in real-time

---

## 📱 After Rebuild

### If you built release APK:

1. **Find APK**:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Transfer to phone** and install

3. **Open app** - it should now connect to AWS backend

---

### If you ran in debug mode:

1. App will launch automatically on connected device
2. Check logs - should show:
   ```
   [Backend] Testing connection to: http://51.20.89.101
   ```

---

## 🧪 Verify It's Working

After rebuilding and installing, you should see in logs:

### ✅ Before (Wrong):
```
[Backend] Testing connection to: http://192.168.43.104:3000
❌ [Backend] Connection failed!
```

### ✅ After (Correct):
```
[Backend] Testing connection to: http://51.20.89.101
✅ [Backend] Connection successful!
```

---

## 🔍 Why This Happened

Flutter apps bundle the `.env` file during build time:

1. **First build**: `.env` had `http://192.168.43.104:3000`
2. **We updated**: `.env` now has `http://51.20.89.101`
3. **App still has old value**: Because it was already built
4. **Solution**: Rebuild to pick up new value

---

## ⚡ Quick Command

Copy and paste this:

```powershell
cd "D:\projects\orginize app\orginizeapp" ; flutter clean ; flutter pub get ; flutter build apk --release
```

---

## 📊 What Will Happen

1. **flutter clean**: Removes old build files
2. **flutter pub get**: Gets dependencies
3. **flutter build apk**: Builds new APK with updated `.env`

**Result**: App will use AWS backend `http://51.20.89.101` ✅

---

## 🎯 After Rebuild - Test Checklist

- [ ] App connects to AWS backend
- [ ] No timeout errors
- [ ] Can login
- [ ] Can browse vendors
- [ ] Can place order
- [ ] Notifications work

---

## 💡 Pro Tip

For faster testing during development, use:

```powershell
flutter run --dart-define=STORAGE_BACKEND_URL=http://51.20.89.101
```

This overrides the `.env` value without rebuilding.

---

## 🆘 If Still Shows Old URL

1. **Uninstall old app** from phone completely
2. **Rebuild**:
   ```powershell
   flutter clean
   flutter pub get
   flutter build apk --release
   ```
3. **Install fresh APK**

---

## ✅ Success Indicator

When you open the app, check logs. Should show:

```
[Backend] Testing connection to: http://51.20.89.101
[Backend] Endpoint: http://51.20.89.101/api/debug/ping
✅ [Backend] Connection successful!
```

---

**Run the rebuild command now!** 🚀

```powershell
cd "D:\projects\orginize app\orginizeapp"
flutter clean
flutter pub get
flutter build apk --release
```
