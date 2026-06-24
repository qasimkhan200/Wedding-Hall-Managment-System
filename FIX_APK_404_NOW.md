# Fix APK 404 Error - Simple Steps

## 🔍 What's Wrong

Your download route code exists in `src/index.ts` and `src/routes/download.ts`, but PM2 is running **old compiled code** from the `dist/` folder.

## ✅ Simple Fix (Run These Commands)

You're already in the right directory (`~/backend/backend`). Just run:

```bash
# Step 1: Create the downloads folder
mkdir -p public/downloads

# Step 2: Compile TypeScript to JavaScript
npm run build

# Step 3: Restart PM2 to load new code
pm2 restart backend

# Step 4: Wait 2 seconds
sleep 2

# Step 5: Test the endpoint
curl http://localhost/api/download/apk/info
```

## 📋 Copy-Paste This One Command

```bash
mkdir -p public/downloads && npm run build && pm2 restart backend && sleep 2 && curl http://localhost/api/download/apk/info
```

---

## 🎯 Expected Result

You should see:

```json
{
  "available": false,
  "message": "APK not available. Please place app-release.apk or app-debug.apk in backend/public/downloads/ folder"
}
```

This means the route is working! ✅

---

## 📦 Next Step: Upload APK

### From Your Local Machine:

```bash
# Build the APK
cd "D:\projects\orginize app\orginizeapp"
flutter build apk --release

# Upload to server
scp build/app/outputs/flutter-apk/app-release.apk ubuntu@51.20.89.101:/home/ubuntu/backend/backend/public/downloads/

# Test again
curl http://51.20.89.101/api/download/apk/info
```

Now you should see:

```json
{
  "available": true,
  "filename": "OrganizeApp.apk",
  "size": "XX.X MB",
  "downloadUrl": "/api/download/apk"
}
```

---

## 🌐 Test URLs

After the fix:

- **APK Info:** http://51.20.89.101/api/download/apk/info
- **Download APK:** http://51.20.89.101/api/download/apk
- **Website:** http://localhost:3000 (your React app)

---

## 🐛 If Still Not Working

Check PM2 logs:

```bash
pm2 logs backend --lines 50
```

Look for:
```
✅ /api/download
```

If you don't see this, the build failed. Check for errors:

```bash
npm run build
```

---

## ✅ Quick Checklist

- [ ] Run: `mkdir -p public/downloads`
- [ ] Run: `npm run build`
- [ ] Run: `pm2 restart backend`
- [ ] Test: `curl http://localhost/api/download/apk/info`
- [ ] Should return JSON (not 404)
- [ ] Upload APK: `scp app-release.apk ubuntu@51.20.89.101:~/backend/backend/public/downloads/`
- [ ] Test download: `curl http://51.20.89.101/api/download/apk/info`

---

**Run the one-line command above and it should work!** 🚀
