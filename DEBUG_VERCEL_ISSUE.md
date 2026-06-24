# Debug Vercel "App Not Available" Issue

## 🔍 What I've Added

I've added debugging tools to help identify the issue:

1. **Enhanced logging in Hero.js** - Shows what's happening
2. **DebugInfo component** - Shows environment variables and tests backend connection
3. **Better error messages** - Shows actual error instead of generic message

---

## 🚀 How to Debug

### Step 1: Test Locally First

```bash
cd website
npm start
```

Open http://localhost:3000 and check:
- Does it show "Download App (104.47 MB)"?
- Open browser console (F12) - any errors?
- Check the debug panel at bottom-right

### Step 2: Deploy to Vercel

```bash
cd website
git add .
git commit -m "Add debugging tools"
git push
```

Wait for Vercel to deploy (1-2 minutes).

### Step 3: Check Vercel Site with Debug Mode

Open your Vercel site with debug parameter:
```
https://your-site.vercel.app/?debug=true
```

This will show the debug panel at bottom-right with:
- Current backend URL
- Environment variables
- Test connection button

### Step 4: Check Browser Console

1. Open your Vercel site
2. Press F12 (open DevTools)
3. Go to **Console** tab
4. Look for messages starting with:
   - `🔍 [Hero] Backend URL:`
   - `📥 [Hero] Response status:`
   - `❌ [Hero] Failed to fetch APK info:`

### Step 5: Check Network Tab

1. In DevTools, go to **Network** tab
2. Refresh the page
3. Look for request to: `http://51.20.89.101/api/download/apk/info`
4. Click on it to see:
   - Status code (should be 200)
   - Response body
   - Any errors

---

## 🐛 Common Issues & Solutions

### Issue 1: Environment Variable Not Set

**Symptom:** Debug panel shows `Backend URL: http://localhost:3000`

**Solution:**
1. Go to Vercel Dashboard → Your Project → Settings → Environment Variables
2. Verify `REACT_APP_BACKEND_URL` exists with value `http://51.20.89.101`
3. Make sure it's enabled for **Production**
4. Redeploy

### Issue 2: CORS Error

**Symptom:** Console shows:
```
Access to fetch at 'http://51.20.89.101/api/download/apk/info' 
from origin 'https://your-site.vercel.app' has been blocked by CORS
```

**Solution:** Your backend already has CORS enabled, but double-check:
```bash
ssh ubuntu@51.20.89.101
cd ~/backend/backend
grep -n "cors" src/index.ts
```

Should show: `app.use(cors());`

### Issue 3: Mixed Content (HTTPS → HTTP)

**Symptom:** Console shows:
```
Mixed Content: The page at 'https://...' was loaded over HTTPS, 
but requested an insecure XMLHttpRequest endpoint 'http://...'
```

**Solution:** This is expected. Most browsers allow it for downloads. If blocked:
- Use HTTPS for backend (add SSL certificate)
- Or use a proxy

### Issue 4: Backend Not Responding

**Symptom:** Network tab shows request failed or timeout

**Solution:** Test backend directly:
```bash
curl http://51.20.89.101/api/download/apk/info
```

Should return JSON. If not, restart backend:
```bash
ssh ubuntu@51.20.89.101
cd ~/backend/backend
pm2 restart backend
```

### Issue 5: Build Cache Issue

**Symptom:** Changes not reflected on Vercel

**Solution:** Force rebuild without cache:
1. Vercel Dashboard → Deployments
2. Click **...** on latest deployment
3. Click **Redeploy**
4. **Uncheck** "Use existing Build Cache"
5. Click **Redeploy**

---

## 📋 Debugging Checklist

Run through this checklist:

### On Vercel Dashboard:
- [ ] Go to Settings → Environment Variables
- [ ] Verify `REACT_APP_BACKEND_URL` exists
- [ ] Value is: `http://51.20.89.101` (no trailing slash)
- [ ] Enabled for: Production ✅
- [ ] Click Save (if you made changes)

### On Your Vercel Site:
- [ ] Open: `https://your-site.vercel.app/?debug=true`
- [ ] Check debug panel shows correct backend URL
- [ ] Click "Test Backend Connection" button
- [ ] Check result - should show `success: true`

### In Browser Console:
- [ ] Press F12
- [ ] Go to Console tab
- [ ] Look for `🔍 [Hero] Backend URL:` message
- [ ] Should show: `http://51.20.89.101`
- [ ] Look for `✅ [Hero] APK info received:` message
- [ ] Should show APK data

### In Network Tab:
- [ ] Press F12
- [ ] Go to Network tab
- [ ] Refresh page
- [ ] Find request to `/api/download/apk/info`
- [ ] Status should be: 200 OK
- [ ] Response should show APK data

### Test Backend Directly:
- [ ] Open new tab
- [ ] Go to: `http://51.20.89.101/api/download/apk/info`
- [ ] Should show JSON with APK info
- [ ] If not, backend is down

---

## 🎯 What to Look For

After deploying with debug tools, tell me:

1. **What does the debug panel show?**
   - Backend URL: ?
   - Environment: ?
   - Test result: ?

2. **What's in the browser console?**
   - Any errors?
   - What does `🔍 [Hero] Backend URL:` show?

3. **What's in the Network tab?**
   - Does request to backend appear?
   - What's the status code?
   - What's the response?

4. **Does backend work directly?**
   - Open: http://51.20.89.101/api/download/apk/info
   - Does it return JSON?

---

## 🚀 Quick Test Commands

### Test Backend from Command Line:
```bash
# Test backend health
curl http://51.20.89.101/health

# Test APK info endpoint
curl http://51.20.89.101/api/download/apk/info

# Should return:
# {"available":true,"filename":"OrganizeApp-Debug.apk",...}
```

### Check Vercel Environment Variables:
```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# List environment variables
vercel env ls

# Should show:
# REACT_APP_BACKEND_URL (Production, Preview, Development)
```

### Force Redeploy:
```bash
cd website
git commit --allow-empty -m "Force redeploy"
git push
```

---

## 📝 Next Steps

1. **Deploy the changes:**
   ```bash
   cd website
   git add .
   git commit -m "Add debugging tools"
   git push
   ```

2. **Wait for deployment** (1-2 minutes)

3. **Open with debug mode:**
   ```
   https://your-site.vercel.app/?debug=true
   ```

4. **Check the debug panel** and tell me what you see

5. **Check browser console** (F12) and share any errors

---

**With these debugging tools, we'll quickly identify the exact issue!** 🔍
