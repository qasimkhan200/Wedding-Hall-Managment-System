// Run: node create_admin.js
// Requires: npm install firebase-admin

const admin = require('firebase-admin');

// Download your service account key from:
// Firebase Console → Project Settings → Service Accounts → Generate new private key
// Save it as serviceAccountKey.json in the same folder as this script
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

// ── CHANGE THESE ──────────────────────────────────────
const ADMIN_EMAIL    = 'admin@orginize.com';   // your email
const ADMIN_PASSWORD = 'Admin@123456';          // strong password
const ADMIN_NAME     = 'Admin';
// ──────────────────────────────────────────────────────

async function createAdmin() {
  try {
    console.log('Creating Firebase Auth user...');
    const userRecord = await auth.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      displayName: ADMIN_NAME,
    });

    const uid = userRecord.uid;
    console.log('Auth user created. UID:', uid);

    console.log('Creating Firestore document...');
    await db.collection('users').doc(uid).set({
      id: uid,
      name: ADMIN_NAME,
      email: ADMIN_EMAIL,
      role: 'admin',
      isApproved: true,
      phone: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Admin account created successfully!');
    console.log('   Email:   ', ADMIN_EMAIL);
    console.log('   Password:', ADMIN_PASSWORD);
    console.log('   UID:     ', uid);
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

createAdmin();
