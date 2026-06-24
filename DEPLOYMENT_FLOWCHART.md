# 🗺️ AWS Deployment Flowchart

## Visual Guide: Local Computer → AWS EC2

```
┌─────────────────────────────────────────────────────────────────┐
│                    YOUR LOCAL COMPUTER (Windows)                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Step 1: Prepare
                              ▼
                    ┌──────────────────┐
                    │  Run PowerShell  │
                    │  prepare script  │
                    └──────────────────┘
                              │
                              │ Creates
                              ▼
                    ┌──────────────────┐
                    │ backend-deploy/  │
                    │  ├─ dist/        │
                    │  ├─ package.json │
                    │  └─ firebase.json│
                    └──────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                    Step 2: Launch EC2                     │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │   AWS Console      │                   │
│                  │  EC2 Dashboard     │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             │ Click "Launch Instance"     │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Configure:        │                   │
│                  │  • Ubuntu 22.04    │                   │
│                  │  • t2.micro/small  │                   │
│                  │  • Create key pair │                   │
│                  │  • Security groups │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             │ Download                    │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │ orginizeapp-key.pem│                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             │ Get                         │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Public IP Address │                   │
│                  │   (3.15.123.45)    │                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                    Step 3: Connect via SSH                │
│                             │                             │
│                             ▼                             │
│         ssh -i key.pem ubuntu@YOUR-EC2-IP                 │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │   EC2 Terminal     │                   │
│                  │   (Ubuntu Shell)   │                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                  Step 4: Setup Server                     │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Install Software: │                   │
│                  │  • Node.js 20      │                   │
│                  │  • PM2             │                   │
│                  │  • Nginx           │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Create Directory: │                   │
│                  │  /var/www/         │                   │
│                  │  orginizeapp-      │                   │
│                  │  backend/          │                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                  Step 5: Upload Files                     │
│                             │                             │
│         ┌───────────────────┴───────────────────┐         │
│         │                                       │         │
│         ▼                                       ▼         │
│  ┌─────────────┐                        ┌─────────────┐  │
│  │   WinSCP    │                        │     SCP     │  │
│  │   (GUI)     │                        │  (Command)  │  │
│  └─────────────┘                        └─────────────┘  │
│         │                                       │         │
│         └───────────────────┬───────────────────┘         │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Files on EC2:     │                   │
│                  │  /var/www/         │                   │
│                  │  orginizeapp-      │                   │
│                  │  backend/          │                   │
│                  │    ├─ dist/        │                   │
│                  │    ├─ package.json │                   │
│                  │    └─ firebase.json│                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                Step 6: Configure Environment              │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Create .env file: │                   │
│                  │  • PORT=3000       │                   │
│                  │  • BASE_URL        │                   │
│                  │  • API_KEY         │                   │
│                  │  • FIREBASE_PATH   │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  npm install       │                   │
│                  │  --production      │                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                  Step 7: Start Application                │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  PM2 Process       │                   │
│                  │  Manager           │                   │
│                  │  (Keeps app alive) │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             │ Starts                      │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Node.js App       │                   │
│                  │  Port 3000         │                   │
│                  │  (Backend API)     │                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                  Step 8: Configure Nginx                  │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Nginx Web Server  │                   │
│                  │  Port 80 (HTTP)    │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             │ Proxy to                    │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  localhost:3000    │                   │
│                  │  (Your Node.js)    │                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                  Step 9: Configure Firewall               │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  UFW Firewall:     │                   │
│                  │  • Allow SSH (22)  │                   │
│                  │  • Allow HTTP (80) │                   │
│                  │  • Allow HTTPS(443)│                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                      Step 10: Test                        │
│                             │                             │
│                             ▼                             │
│              http://YOUR-EC2-IP/health                    │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  {"status":"ok"}   │                   │
│                  │  ✅ Working!        │                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│              Step 11: Update Flutter App                  │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  env_config.dart:  │                   │
│                  │  storageBackendUrl │                   │
│                  │  = 'http://EC2-IP' │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  flutter build apk │                   │
│                  └────────────────────┘                   │
│                             │                             │
│                             ▼                             │
│                  ┌────────────────────┐                   │
│                  │  Install on Phone  │                   │
│                  │  Test Notifications│                   │
│                  └────────────────────┘                   │
└───────────────────────────────────────────────────────────┘
                              │
                              │
                              ▼
                    ┌──────────────────┐
                    │   🎉 SUCCESS!    │
                    │  Backend is LIVE │
                    │     on AWS EC2   │
                    └──────────────────┘
```

---

## 🔄 Data Flow After Deployment

```
┌─────────────────┐
│  Flutter App    │
│  (Your Phone)   │
└────────┬────────┘
         │
         │ HTTP Request
         │ (Place Order, Upload Image, etc.)
         │
         ▼
┌─────────────────────────────────────────┐
│         AWS EC2 Instance                │
│  ┌───────────────────────────────────┐  │
│  │  Nginx (Port 80)                  │  │
│  │  • Receives HTTP requests         │  │
│  │  • Handles SSL (if configured)    │  │
│  └──────────────┬────────────────────┘  │
│                 │                        │
│                 │ Proxy to               │
│                 ▼                        │
│  ┌───────────────────────────────────┐  │
│  │  Node.js Backend (Port 3000)      │  │
│  │  • Express API                    │  │
│  │  • Image processing (Sharp)       │  │
│  │  • FCM notifications              │  │
│  └──────────────┬────────────────────┘  │
│                 │                        │
│                 │ Managed by             │
│                 ▼                        │
│  ┌───────────────────────────────────┐  │
│  │  PM2 Process Manager              │  │
│  │  • Auto-restart on crash          │  │
│  │  • Logs management                │  │
│  │  • Auto-start on server reboot    │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         │
         │ Connects to
         ▼
┌─────────────────┐
│  Firebase       │
│  • Firestore    │
│  • FCM Tokens   │
│  • Auth         │
└─────────────────┘
```

---

## 📊 Architecture Overview

```
                    BEFORE (Local Development)
                    ═════════════════════════

┌──────────────┐                    ┌──────────────┐
│   Emulator   │ ──────────────────▶│   Backend    │
│  (10.0.2.2)  │  localhost:3000    │  (Your PC)   │
└──────────────┘                    └──────────────┘
                                           │
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │   Firebase   │
                                    └──────────────┘


                    AFTER (Production on AWS)
                    ═════════════════════════

┌──────────────┐                    ┌──────────────┐
│ Physical     │ ──────────────────▶│   AWS EC2    │
│ Device       │  http://EC2-IP     │   Backend    │
│ (Anywhere)   │                    │  (Cloud)     │
└──────────────┘                    └──────────────┘
                                           │
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │   Firebase   │
                                    └──────────────┘
```

---

## 🔐 Security Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Internet (Public)                     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  AWS Security Group  │
              │  • Port 22 (SSH)     │
              │  • Port 80 (HTTP)    │
              │  • Port 443 (HTTPS)  │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  UFW Firewall        │
              │  • Allow Nginx       │
              │  • Allow SSH         │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Nginx               │
              │  • Rate limiting     │
              │  • Request filtering │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Backend API         │
              │  • API Key check     │
              │  • Input validation  │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Firebase            │
              │  • Auth tokens       │
              │  • Security rules    │
              └──────────────────────┘
```

---

## 📁 File Structure on EC2

```
/var/www/orginizeapp-backend/
│
├── dist/                          # Compiled JavaScript
│   ├── index.js                   # Main entry point
│   ├── config.js                  # Configuration
│   ├── firebase/
│   │   └── admin.js               # Firebase Admin SDK
│   ├── routes/
│   │   ├── notifications.js       # Notification endpoints
│   │   ├── orderProofs.js         # Order proof uploads
│   │   ├── itemImages.js          # Item image uploads
│   │   └── profiles.js            # Profile image uploads
│   └── notifications/
│       ├── fcmService.js          # FCM push notifications
│       └── tokenStore.js          # Token management
│
├── node_modules/                  # Dependencies (installed on server)
│
├── uploads/                       # Uploaded files (created automatically)
│   ├── order-proofs/
│   ├── item-images/
│   ├── venue-photos/
│   └── profiles/
│
├── package.json                   # Dependencies list
├── package-lock.json              # Locked versions
├── .env                           # Environment variables (SECRET!)
└── firebase-service-account.json  # Firebase credentials (SECRET!)
```

---

## 🔄 Update Process

```
┌─────────────────────────────────────────────────────────┐
│                  Make Code Changes                       │
│                  (On Local Computer)                     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  npm run build       │
              │  (Compile TS → JS)   │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Upload dist/ folder │
              │  via SCP or WinSCP   │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  SSH to EC2          │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  pm2 restart app     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  pm2 logs            │
              │  (Verify changes)    │
              └──────────────────────┘
```

---

## 📚 Related Guides

- **Quick Start**: [DEPLOYMENT_QUICK_START.md](DEPLOYMENT_QUICK_START.md)
- **Detailed Checklist**: [backend/DEPLOYMENT_CHECKLIST.md](backend/DEPLOYMENT_CHECKLIST.md)
- **Complete Manual**: [AWS_MANUAL_DEPLOYMENT.md](AWS_MANUAL_DEPLOYMENT.md)
- **All Options**: [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)

---

## 🎯 Key Takeaways

1. **Local → EC2**: Upload compiled code, not source
2. **PM2**: Keeps your app running 24/7
3. **Nginx**: Handles web traffic and proxies to Node.js
4. **Firewall**: Multiple layers of security
5. **Updates**: Build locally, upload dist/, restart PM2

---

## ✅ Success Indicators

- ✅ `http://YOUR-EC2-IP/health` returns `{"status":"ok"}`
- ✅ `pm2 status` shows "online"
- ✅ `sudo systemctl status nginx` shows "active (running)"
- ✅ Flutter app can connect to backend
- ✅ Notifications work end-to-end
- ✅ Images upload successfully

---

## 🎉 You're Ready!

Follow the flowchart step-by-step, and you'll have your backend running on AWS in 30 minutes!
