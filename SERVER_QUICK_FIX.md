# Server Quick Fix - APK Download

## 🔍 Issue Found

You're in: `~/backend/backend` (double backend directory)
But PM2 might be running from: `~/backend`

The route code exists but PM2 needs to be restarted from the correct directory.

## ✅ Quick Fix Commands

Run these commands on your server:

```bash
# Step 1: Go to the correct backend directory
cd ~/backend/backend

# Step 2: Check if download route file exists
ls -la src/routes/download.ts

# Step 3: Check if public/downloads folder exists
ls -la public/downloads/

# Step 4: Create downloads folder if it doesn't exist
mkdir -p public/downloads

# Step 5: Rebuild the backend (compile TypeScript)
npm run build

# Step 6: Restart PM2 from this directory
pm2 restart backend

# Step 7: Check PM2 logs
pm2 logs backend --lines 30

# Step 8: Test the endpoint
curl http://localhost/api/download/apk/info
```

---

## 🎯 Expected Output

After running the commands, you should see in PM2 logs:

```
📥 Registering download routes...
  ✅ /api/download
```

And the curl command should return:

```json
{
  "available": false,
  "message": "APK not available. Please place app-release.apk or app-debug.apk in backend/public/downloads/ folder"
}
```

---

## 📦 Upload APK File

Once the route is working, upload your APK:

### From Your Local Machine:

```bash
# Build APK
cd /path/to/flutter/project
flutter build apk --release

# Upload to server
scp build/app/outputs/flutter-apk/app-release.apk \
    ubuntu@51.20.89.101:/home/ubuntu/backend/backend/public/downloads/

# Set permissions
ssh ubuntu@51.20.89.101 "chmod 644 /home/ubuntu/backend/backend/public/downloads/app-release.apk"

# Test
curl http://51.20.89.101/api/download/apk/info
```

---

## 🔍 Verify PM2 Working Directory

Check where PM2 is actually running from:

```bash
# Check PM2 process details
pm2 describe backend

# Look for "cwd" (current working directory)
# It should show: /home/ubuntu/backend/backend
```

If it shows a different directory, update PM2:

```bash
# Delete old PM2 process
pm2 delete backend

# Start from correct directory
cd ~/backend/backend
pm2 start dist/index.js --name backend

# Save PM2 config
pm2 save
```

---

## 📋 Complete Fix Script

Copy and paste this entire block:

```bash
cd ~/backend/backend && \
mkdir -p public/downloads && \
npm run build && \
pm2 restart backend && \
sleep 2 && \
pm2 logs backend --lines 20 && \
echo "Testing endpoint..." && \
curl http://localhost/api/download/apk/info
```

---

## ✅ Success Indicators

You'll know it's working when:

1. **PM2 logs show:**
   ```
   ✅ /api/download
   ```

2. **Curl returns JSON (not 404):**
   ```json
   {
     "available": false,
     "message": "APK not available..."
   }
   ```

3. **After uploading APK:**
   ```json
   {
     "available": true,
     "filename": "OrganizeApp.apk",
     "size": "25.3 MB"
   }
   ```

---

## 🚀 Test URLs

After fix:

- **Info:** http://51.20.89.101/api/download/apk/info
- **Download:** http://51.20.89.101/api/download/apk

---

**Run the commands above and the download route should work!** 🎉
