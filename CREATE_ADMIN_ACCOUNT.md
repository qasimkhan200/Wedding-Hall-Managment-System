# 🔐 Create Admin Account

## Admin Account Details

Since admin registration is blocked in the UI, you need to create the admin account manually in Firebase.

---

## 📝 Recommended Admin Credentials

```
Email: admin@orginizeapp.com
Password: Admin@123456
Name: Admin User
Phone: +1234567890
Role: admin
```

**⚠️ IMPORTANT:** Change the password after first login!

---

## 🚀 Method 1: Firebase Console (Easiest)

### Step 1: Create Firebase Auth User
1. Go to: https://console.firebase.google.com/project/orginize-app/authentication/users
2. Click **"Add user"**
3. Enter:
   - Email: `admin@orginizeapp.com`
   - Password: `Admin@123456`
4. Click **"Add user"**
5. **Copy the User UID** (you'll need it in Step 2)

### Step 2: Create Firestore User Document
1. Go to: https://console.firebase.google.com/project/orginize-app/firestore/data
2. Click on **"users"** collection (or create it if it doesn't exist)
3. Click **"Add document"**
4. For Document ID: **Paste the UID from Step 1**
5. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `email` | string | `admin@orginizeapp.com` |
| `name` | string | `Admin User` |
| `phone` | string | `+1234567890` |
| `role` | string | `admin` |
| `isActive` | boolean | `true` |
| `isApproved` | boolean | `true` |
| `createdAt` | number | `1703001600000` (or current timestamp) |
| `updatedAt` | number | `1703001600000` (or current timestamp) |

6. Click **"Save"**

### Step 3: Test Admin Login
1. Open your app
2. Since Admin is hidden from role selection, you have 2 options:

**Option A: Temporarily show Admin in role selection**
- Edit `lib/features/auth/screens/role_selection_screen.dart`
- Uncomment the Admin role card
- Run the app
- Select Admin → Login
- After testing, hide it again

**Option B: Direct admin login URL** (if you implement it)
- Create a special admin login route
- Navigate directly to admin login

3. Login with:
   - Email: `admin@orginizeapp.com`
   - Password: `Admin@123456`

4. You should see the Admin dashboard!

---

## 🔧 Method 2: Using Firebase CLI (Advanced)

If you have Node.js and Firebase Admin SDK:

### Step 1: Install Firebase Admin
```bash
npm install firebase-admin
```

### Step 2: Create Script
Create `create-admin.js`:

```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json'); // Download from Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function createAdmin() {
  try {
    // Create Firebase Auth user
    const userRecord = await admin.auth().createUser({
      email: 'admin@orginizeapp.com',
      password: 'Admin@123456',
      displayName: 'Admin User',
    });

    console.log('✅ Firebase Auth user created:', userRecord.uid);

    // Create Firestore user document
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email: 'admin@orginizeapp.com',
      name: 'Admin User',
      phone: '+1234567890',
      role: 'admin',
      isActive: true,
      isApproved: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Firestore user document created');
    console.log('\n🎉 Admin account created successfully!');
    console.log('Email: admin@orginizeapp.com');
    console.log('Password: Admin@123456');
    console.log('\n⚠️  Please change the password after first login!');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating admin:', error);
    process.exit(1);
  }
}

createAdmin();
```

### Step 3: Run Script
```bash
node create-admin.js
```

---

## 🧪 Verify Admin Account

### Check Firebase Authentication:
1. Go to: https://console.firebase.google.com/project/orginize-app/authentication/users
2. You should see: `admin@orginizeapp.com`

### Check Firestore:
1. Go to: https://console.firebase.google.com/project/orginize-app/firestore/data
2. Navigate to `users` collection
3. Find document with admin's UID
4. Verify fields:
   - ✅ `role: "admin"`
   - ✅ `isApproved: true`
   - ✅ `isActive: true`

---

## 🔓 How to Login as Admin

### Option 1: Temporarily Show Admin Role
1. Edit `lib/features/auth/screens/role_selection_screen.dart`
2. Add back the Admin role card:

```dart
const SizedBox(height: 16),
_RoleCard(
  icon: '👨‍💼',
  title: 'Admin',
  subtitle: 'Manage platform and approvals',
  color: AppColors.info,
  onTap: () => _navigateToLogin(context, AppConstants.roleAdmin),
),
```

3. Run app → Select Admin → Login
4. After testing, remove it again

### Option 2: Create Admin Login Screen
Create a separate admin login screen accessible via:
- Deep link: `yourapp://admin-login`
- Secret gesture (e.g., tap logo 5 times)
- Direct navigation in code

---

## 🔐 Security Best Practices

1. **Change Default Password**
   - Login as admin
   - Go to Settings/Profile
   - Change password to something secure

2. **Use Strong Password**
   - Minimum 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Example: `Adm!n$ecure2024#`

3. **Limit Admin Access**
   - Only create admin accounts for trusted users
   - Keep admin credentials secure
   - Don't share admin login

4. **Monitor Admin Activity**
   - Log admin actions
   - Review approval history
   - Track changes

---

## 📋 Quick Reference

**Default Admin Credentials:**
```
Email: admin@orginizeapp.com
Password: Admin@123456
```

**Firebase Console Links:**
- Authentication: https://console.firebase.google.com/project/orginize-app/authentication/users
- Firestore: https://console.firebase.google.com/project/orginize-app/firestore/data

**What Admin Can Do:**
- ✅ Approve/reject vendor applications
- ✅ Approve/reject rider applications
- ✅ View all users
- ✅ Activate/deactivate accounts
- ✅ View platform statistics
- ✅ Manage all orders

---

## ❓ Troubleshooting

### "User not found" error
- Check that Firestore document ID matches Firebase Auth UID
- Verify document exists in `users` collection

### "Your account is pending approval" error
- Check `isApproved` field is `true` in Firestore
- Check `role` field is `"admin"` (not "Admin")

### Can't see Admin in role selection
- This is intentional! Admin is hidden from public registration
- Use Option 1 or 2 above to login

### Admin dashboard not loading
- Verify admin user has `role: "admin"` in Firestore
- Check that admin routes are properly configured

---

## ✅ Summary

1. Create Firebase Auth user: `admin@orginizeapp.com`
2. Create Firestore document with `role: "admin"` and `isApproved: true`
3. Temporarily show Admin in role selection to login
4. Change password after first login
5. Hide Admin role again

**Your admin account is ready to use!** 🎉
