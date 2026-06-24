# 🔧 Fix 404 Error on /api Routes

## ❌ Problem

Your backend is working, but `/api` routes return 404:

- ✅ `http://51.20.89.101/health` → Works
- ❌ `http://51.20.89.101/api/debug/ping` → 404 Not Found

## 🎯 Root Cause

Nginx configuration issue - it's not properly proxying `/api` routes to your Node.js backend.

---

## ✅ Solution: Fix Nginx Configuration

### Step 1: SSH into Your Server

```powershell
ssh -i orginizeapp-key.pem ubuntu@51.20.89.101
```

### Step 2: Check Current Nginx Config

```bash
cat /etc/nginx/sites-available/orginizeapp
```

### Step 3: Edit Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/orginizeapp
```

### Step 4: Replace with This Configuration

**Delete everything** and paste this:

```nginx
server {
    listen 80;
    server_name 51.20.89.101;

    # Increase upload size for images
    client_max_body_size 10M;

    # Proxy all requests to Node.js backend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

**Save and exit**:
- Press `Ctrl + X`
- Press `Y`
- Press `Enter`

### Step 5: Test Nginx Configuration

```bash
sudo nginx -t
```

**Expected output**:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Step 6: Restart Nginx

```bash
sudo systemctl restart nginx
```

### Step 7: Verify Backend is Running

```bash
pm2 status
```

Should show `orginizeapp-backend` as `online`.

If not running:
```bash
pm2 restart orginizeapp-backend
```

---

## 🧪 Test After Fix

### From Your Computer (PowerShell):

```powershell
# Test 1: Health check (should still work)
curl http://51.20.89.101/health

# Test 2: Debug ping (should now work!)
curl http://51.20.89.101/api/debug/ping
```

**Expected response for Test 2**:
```json
{
  "success": true,
  "message": "🎉 Backend is accessible!",
  "firebase": {
    "initialized": true
  }
}
```

---

## 🔍 Alternative: Check if Backend is Listening

If still not working, verify backend is running:

```bash
# Check if Node.js is listening on port 3000
sudo netstat -tulpn | grep 3000
```

**Expected output**:
```
tcp        0      0 0.0.0.0:3000            0.0.0.0:*               LISTEN      12345/node
```

If nothing shows, backend isn't running:

```bash
# Check PM2 logs
pm2 logs orginizeapp-backend --lines 50

# Restart backend
pm2 restart orginizeapp-backend
```

---

## 🎯 Quick Fix Commands (Copy-Paste)

```bash
# SSH into server
ssh -i orginizeapp-key.pem ubuntu@51.20.89.101

# Edit Nginx config
sudo nano /etc/nginx/sites-available/orginizeapp

# After editing, test and restart
sudo nginx -t
sudo systemctl restart nginx

# Check backend
pm2 status
pm2 logs orginizeapp-backend --lines 20

# Test from server
curl http://localhost:3000/health
curl http://localhost:3000/api/debug/ping
```

---

## 📊 What Should Work After Fix

| URL | Status | Response |
|-----|--------|----------|
| `http://51.20.89.101/health` | ✅ 200 | `{"status":"ok"}` |
| `http://51.20.89.101/api/debug/ping` | ✅ 200 | `{"success":true}` |
| `http://51.20.89.101/api/notifications/register-token` | ✅ 200/401 | Works (may need API key) |

---

## 🔧 Troubleshooting

### Still Getting 404?

**Check 1: Backend is running**
```bash
pm2 status
# Should show: online
```

**Check 2: Backend responds locally**
```bash
curl http://localhost:3000/api/debug/ping
# Should return JSON
```

**Check 3: Nginx is running**
```bash
sudo systemctl status nginx
# Should show: active (running)
```

**Check 4: Nginx error logs**
```bash
sudo tail -f /var/log/nginx/error.log
# Look for errors
```

---

### Backend Not Running?

```bash
# Check why it stopped
pm2 logs orginizeapp-backend --lines 100

# Common issues:
# 1. Missing .env file
# 2. Firebase credentials missing
# 3. Port already in use

# Restart
pm2 restart orginizeapp-backend
```

---

### Nginx Not Starting?

```bash
# Check syntax
sudo nginx -t

# View error log
sudo tail -20 /var/log/nginx/error.log

# Restart
sudo systemctl restart nginx
```

---

## ✅ Success Indicators

After fixing, your Flutter app should show:

```
[Backend] Testing connection to: http://51.20.89.101
[Backend] Endpoint: http://51.20.89.101/api/debug/ping
✅ [Backend] Connection successful!
✅ [Backend] Response: {"success":true,"message":"🎉 Backend is accessible!"}
```

---

## 🎉 Once Fixed

Your app will:
- ✅ Connect to AWS backend
- ✅ Register FCM tokens
- ✅ Send notifications
- ✅ Upload images
- ✅ Process orders

---

**Fix the Nginx config now and test!** 🚀
