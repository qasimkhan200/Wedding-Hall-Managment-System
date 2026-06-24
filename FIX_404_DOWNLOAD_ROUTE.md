# Fix 404 Error for Download Route

## 🔴 Problem

The backend is returning 404 for `/api/download/apk/info`:

```
Response Status: 404
Response Body: {"error":"Not found","method":"GET","url":"/api/download/apk/info"}
```

## 💡 Root Cause

The download router is either:
1. Not deployed to the server
2. Not registered in the backend
3. Backend code on server is outdated

## ✅ Solution

### Step 1: Check if Download Route File Exists on Server

SSH into your server:

```bash
ssh ubuntu@51.20.89.101

# Navigate to backend directory
cd /home/ubuntu/backend  # or wherever your backend is

# Check if download route exists
ls -la src/routes/download.ts

# If it doesn't exist, you need to deploy the latest code
```

### Step 2: Deploy Latest Backend Code

From your local machine, deploy the updated backend:

```bash
# Option A: Using Git (if backend is in a repo)
ssh ubuntu@51.20.89.101
cd /home/ubuntu/backend
git pull origin main
npm install
pm2 restart backend

# Option B: Using SCP to upload files
cd /path/to/your/local/backend
scp -r src ubuntu@51.20.89.101:/home/ubuntu/backend/
ssh ubuntu@51.20.89.101 "cd /home/ubuntu/backend && npm install && pm2 restart backend"

# Option C: Using rsync (recommended)
rsync -avz --exclude 'node_modules' \
  /path/to/local/backend/ \
  ubuntu@51.20.89.101:/home/ubuntu/backend/
ssh ubuntu@51.20.89.101 "cd /home/ubuntu/backend && npm install && pm2 restart backend"
```

### Step 3: Verify Download Route is Registered

Check the backend index.ts on server:

```bash
ssh ubuntu@51.20.89.101
cd /home/ubuntu/backend
cat src/index.ts | grep -A 2 "download"
```

Should show:
```typescript
import downloadRouter from './routes/download';
...
app.use('/api/download', downloadRouter);
```

### Step 4: Rebuild Backend (if using TypeScript)

```bash
ssh ubuntu@51.20.89.101
cd /home/ubuntu/backend
npm run build  # or tsc
pm2 restart backend
```

### Step 5: Check PM2 Logs

```bash
ssh ubuntu@51.20.89.101
pm2 logs backend --lines 50
```

Look for:
```
✅ /api/download
```

This confirms the route is registered.

---

## 🚀 Quick Fix Script

Create this script on your server:

```bash
#!/bin/bash
# fix-download-route.sh

echo "Fixing download route..."

cd /home/ubuntu/backend

# Check if download route exists
if [ ! -f "src/routes/download.ts" ]; then
    echo "❌ download.ts not found!"
    echo "You need to deploy the latest backend code"
    exit 1
fi

# Rebuild
echo "Building backend..."
npm run build

# Restart PM2
echo "Restarting backend..."
pm2 restart backend

# Wait a moment
sleep 2

# Test the endpoint
echo "Testing endpoint..."
curl http://localhost/api/download/apk/info

echo "Done!"
```

Run it:
```bash
chmod +x fix-download-route.sh
./fix-download-route.sh
```

---

## 📋 Complete Deployment Steps

### From Your Local Machine:

```bash
# Step 1: Ensure you have the latest code locally
cd /path/to/your/backend
git status  # Make sure download.ts exists in src/routes/

# Step 2: Deploy to server using rsync
rsync -avz --exclude 'node_modules' --exclude '.git' \
  ./ ubuntu@51.20.89.101:/home/ubuntu/backend/

# Step 3: SSH and rebuild
ssh ubuntu@51.20.89.101 << 'EOF'
cd /home/ubuntu/backend
npm install
npm run build
pm2 restart backend
pm2 logs backend --lines 20
EOF

# Step 4: Test from local machine
curl http://51.20.89.101/api/download/apk/info
```

---

## 🔍 Verification Commands

### 1. Check if Route File Exists:
```bash
ssh ubuntu@51.20.89.101 "ls -la /home/ubuntu/backend/src/routes/download.ts"
```

### 2. Check if Route is Imported:
```bash
ssh ubuntu@51.20.89.101 "grep -n 'download' /home/ubuntu/backend/src/index.ts"
```

### 3. Check PM2 Status:
```bash
ssh ubuntu@51.20.89.101 "pm2 status"
```

### 4. Check Backend Logs:
```bash
ssh ubuntu@51.20.89.101 "pm2 logs backend --lines 50 | grep download"
```

### 5. Test Endpoint:
```bash
curl http://51.20.89.101/api/download/apk/info
```

---

## 🎯 Expected Results

### After Fix:

**1. PM2 Logs should show:**
```
📥 Registering download routes...
  ✅ /api/download
```

**2. Test endpoint should return:**
```json
{
  "available": false,
  "message": "APK not available. Please place app-release.apk..."
}
```
or if APK exists:
```json
{
  "available": true,
  "filename": "OrganizeApp.apk",
  "size": "25.3 MB"
}
```

**3. List routes should include:**
```bash
curl http://51.20.89.101/api/debug/routes | grep download
```

---

## 🐛 Troubleshooting

### Issue 1: "download.ts not found"

**Solution:** Deploy the file from local to server:
```bash
scp src/routes/download.ts ubuntu@51.20.89.101:/home/ubuntu/backend/src/routes/
```

### Issue 2: "Cannot find module './routes/download'"

**Solution:** Rebuild the backend:
```bash
ssh ubuntu@51.20.89.101
cd /home/ubuntu/backend
npm run build
pm2 restart backend
```

### Issue 3: Still getting 404

**Solution:** Check if route is actually registered:
```bash
ssh ubuntu@51.20.89.101
cd /home/ubuntu/backend
grep -A 5 "downloadRouter" src/index.ts
```

Should show:
```typescript
import downloadRouter from './routes/download';
...
app.use('/api/download', downloadRouter);
```

### Issue 4: TypeScript compilation errors

**Solution:** Check for errors:
```bash
ssh ubuntu@51.20.89.101
cd /home/ubuntu/backend
npm run build 2>&1 | grep error
```

---

## 📦 Files to Deploy

Make sure these files are on the server:

```
backend/
├── src/
│   ├── index.ts (with download router import)
│   └── routes/
│       └── download.ts (the download route)
├── public/
│   └── downloads/
│       └── app-release.apk (your APK file)
└── package.json
```

---

## ✅ Complete Fix Checklist

- [ ] SSH into server: `ssh ubuntu@51.20.89.101`
- [ ] Check if `src/routes/download.ts` exists
- [ ] If not, deploy latest backend code
- [ ] Run `npm install`
- [ ] Run `npm run build`
- [ ] Restart PM2: `pm2 restart backend`
- [ ] Check logs: `pm2 logs backend --lines 50`
- [ ] Look for "✅ /api/download" in logs
- [ ] Test endpoint: `curl http://51.20.89.101/api/download/apk/info`
- [ ] Should return JSON (not 404)
- [ ] Upload APK file to `public/downloads/app-release.apk`
- [ ] Test download: `curl -I http://51.20.89.101/api/download/apk`

---

## 🎉 Quick Commands

```bash
# Deploy and restart (one command)
rsync -avz --exclude 'node_modules' ./ ubuntu@51.20.89.101:/home/ubuntu/backend/ && \
ssh ubuntu@51.20.89.101 "cd /home/ubuntu/backend && npm install && npm run build && pm2 restart backend"

# Test
curl http://51.20.89.101/api/download/apk/info
```

---

**The issue is that the download route code is not on your server. Deploy the latest backend code and it will work!** 🚀
