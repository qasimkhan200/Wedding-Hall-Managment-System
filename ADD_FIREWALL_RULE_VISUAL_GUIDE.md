# How to Add Firewall Rule - Visual Step-by-Step Guide

## 🎯 Goal
Allow port 3000 through Windows Firewall so Android emulator can reach your backend.

---

## 📺 Method 1: Using Windows Firewall GUI (Easiest)

### Step 1: Open Windows Firewall
1. Press `Windows + R` on your keyboard
2. Type: `wf.msc`
3. Press `Enter`

**Screenshot location**: Windows Defender Firewall with Advanced Security window will open

### Step 2: Create New Inbound Rule
1. In the left panel, click **"Inbound Rules"**
2. In the right panel, click **"New Rule..."**

### Step 3: Select Rule Type
1. Select **"Port"**
2. Click **"Next"**

### Step 4: Specify Port
1. Select **"TCP"**
2. Select **"Specific local ports"**
3. Type: **3000**
4. Click **"Next"**

### Step 5: Allow Connection
1. Select **"Allow the connection"**
2. Click **"Next"**

### Step 6: Select Profiles
1. Check all three boxes:
   - ☑ Domain
   - ☑ Private
   - ☑ Public
2. Click **"Next"**

### Step 7: Name the Rule
1. Name: **Node Backend Port 3000**
2. Description (optional): **Allows Android emulator to connect to Node.js backend**
3. Click **"Finish"**

### Step 8: Verify Rule is Created
1. In the "Inbound Rules" list, look for **"Node Backend Port 3000"**
2. Make sure it shows:
   - Enabled: **Yes** (green checkmark)
   - Action: **Allow**
   - Protocol: **TCP**
   - Local Port: **3000**

---

## 📺 Method 2: Using PowerShell (Faster if you're comfortable)

### Step 1: Open PowerShell as Administrator
**Option A**: Using Start Menu
1. Click Start button
2. Type: **PowerShell**
3. Right-click **"Windows PowerShell"**
4. Click **"Run as administrator"**
5. Click **"Yes"** on the UAC prompt

**Option B**: Using Windows + X
1. Press `Windows + X` on keyboard
2. Click **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**
3. Click **"Yes"** on the UAC prompt

### Step 2: Run the Command
Copy and paste this command:

```powershell
New-NetFirewallRule -DisplayName "Node Backend Port 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

Press `Enter`

### Step 3: Verify Success
You should see output like:
```
Name                  : {GUID}
DisplayName           : Node Backend Port 3000
Description           : 
Enabled               : True
Profile               : Any
Direction             : Inbound
Action                : Allow
...
```

---

## 📺 Method 3: Using Command Prompt (Alternative)

### Step 1: Open Command Prompt as Administrator
1. Click Start button
2. Type: **cmd**
3. Right-click **"Command Prompt"**
4. Click **"Run as administrator"**
5. Click **"Yes"** on the UAC prompt

### Step 2: Run the Command
Copy and paste this command:

```cmd
netsh advfirewall firewall add rule name="Node Backend Port 3000" dir=in action=allow protocol=TCP localport=3000
```

Press `Enter`

### Step 3: Verify Success
You should see:
```
Ok.
```

---

## ✅ After Adding the Rule

### Step 1: Restart Your Flutter App
In your Flutter terminal:
- Press `R` (capital R) for hot restart
- Or stop (Ctrl+C) and run: `flutter run`

### Step 2: Watch for Success
You should now see in Flutter logs:
```
[FCM] ✅ Token obtained
[FCM] Registering token for user OmmOAVR23kat9euaxPSyKLBk1Oh1
[FCM] ✅ Token registered with backend  ← SUCCESS!
```

And in backend logs:
```
POST /api/notifications/register-token
[TokenStore] Saved token for user OmmOAVR23kat9euaxPSyKLBk1Oh1
```

### Step 3: Send Test Notification
```bash
cd backend
node test-notification.js OmmOAVR23kat9euaxPSyKLBk1Oh1
```

### Step 4: Check Your Emulator
You should see a notification: **"🎉 Test Notification"**

---

## 🔍 How to Verify the Rule Was Added

### Using PowerShell:
```powershell
Get-NetFirewallRule -DisplayName "Node Backend Port 3000"
```

Should show the rule with `Enabled: True`

### Using GUI:
1. Press `Windows + R`
2. Type: `wf.msc`
3. Click "Inbound Rules"
4. Look for "Node Backend Port 3000" in the list
5. Should show green checkmark (enabled)

---

## 🆘 Troubleshooting

### "Access Denied" Error
- You need to run as Administrator
- Right-click PowerShell/CMD and select "Run as administrator"

### Rule Added But Still Not Working
1. **Restart backend**:
   ```bash
   # In backend terminal, press Ctrl+C
   npm run dev
   ```

2. **Restart Flutter app**:
   ```bash
   # In Flutter terminal, press Ctrl+C
   flutter run
   ```

3. **Check antivirus**: Some antivirus software has its own firewall
   - Temporarily disable it to test
   - Or add exception for port 3000

4. **Check VPN**: If you're using a VPN, it might block local connections
   - Temporarily disconnect to test

### Can't Find Windows Firewall
- Press `Windows + I` (Settings)
- Search for "Firewall"
- Click "Windows Defender Firewall"
- Click "Advanced settings" on the left

---

## 📋 Quick Reference

| Method | Difficulty | Time | Best For |
|--------|-----------|------|----------|
| GUI (wf.msc) | Easy | 2 min | Beginners, visual learners |
| PowerShell | Medium | 30 sec | Developers, quick setup |
| Command Prompt | Medium | 30 sec | Alternative to PowerShell |

---

## 🎯 Recommended Method

**I recommend Method 1 (GUI)** because:
- ✅ Visual and easy to follow
- ✅ No typing errors
- ✅ Can verify the rule immediately
- ✅ Works for everyone

---

## 💡 What This Does

**Before**:
```
Android Emulator → tries to connect to 10.0.2.2:3000
                ↓
Windows Firewall → BLOCKS connection ❌
                ↓
Backend → never receives request
                ↓
Flutter → TimeoutException
```

**After**:
```
Android Emulator → tries to connect to 10.0.2.2:3000
                ↓
Windows Firewall → ALLOWS connection ✅
                ↓
Backend → receives request and responds
                ↓
Flutter → Token registered successfully! 🎉
```

---

## ⏱️ Timeline

1. Open Windows Firewall: 10 seconds
2. Create new rule: 1 minute
3. Restart Flutter app: 30 seconds
4. Token registration: 10 seconds
5. Send test notification: 30 seconds

**Total**: ~2-3 minutes

---

## 🎉 Success Indicators

After adding the firewall rule, you'll see:

**Flutter Logs**:
```
✅ [FCM] Token registered with backend
```

**Backend Logs**:
```
✅ POST /api/notifications/register-token
✅ [TokenStore] Saved token for user ...
```

**Test Notification**:
```
✅ SUCCESS! Notification sent
```

**Your Emulator**:
```
✅ 📱 Notification appears!
```

---

**Choose Method 1 (GUI) if you want the easiest visual approach!** 🚀

**Or use Method 2 (PowerShell) if you want the fastest way!** ⚡
