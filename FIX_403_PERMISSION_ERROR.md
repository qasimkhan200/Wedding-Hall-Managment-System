# Fix 403 Permission Denied Error

## 🔴 The Problem

You're getting this error:
```
remote: Permission to j28045147-sys/wedding-emergecy-website-.git denied to j28045147-sys.
fatal: The requested URL returned error: 403
```

This means your Personal Access Token **doesn't have the correct permissions**.

---

## ✅ Solution: Create New Token with Correct Permissions

### Step 1: Delete Old Token (Optional but Recommended)

1. Go to: https://github.com/settings/tokens
2. Login as **j28045147-sys**
3. Find your old token
4. Click **Delete** button
5. Confirm deletion

### Step 2: Create New Token with Correct Scopes

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token"** dropdown
3. Select **"Generate new token (classic)"** ← IMPORTANT!
4. Fill in the form:

   **Note:** `Website Push Token`
   
   **Expiration:** Choose duration (90 days recommended)
   
   **Select scopes:** ← THIS IS CRITICAL!
   
   ✅ **Check `repo`** (Full control of private repositories)
   
   This will automatically check:
   - ✅ repo:status
   - ✅ repo_deployment
   - ✅ public_repo
   - ✅ repo:invite
   - ✅ security_events

5. Scroll down and click **"Generate token"**
6. **COPY THE TOKEN IMMEDIATELY** (you won't see it again!)

---

## 🎯 What the Token Should Look Like

### Classic Token (Recommended):
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
- Starts with `ghp_`
- 40 characters total
- All lowercase letters and numbers

### Fine-Grained Token (Alternative):
```
github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
- Starts with `github_pat_`
- 93 characters total

---

## 🔍 Common Mistakes

### ❌ Mistake 1: Wrong Token Type
**Problem:** Created "Fine-grained token" instead of "Classic token"

**Solution:** Use "Generate new token (classic)" option

### ❌ Mistake 2: Missing `repo` Scope
**Problem:** Didn't check the `repo` checkbox

**Solution:** The `repo` scope MUST be checked for push access

### ❌ Mistake 3: Token Expired
**Problem:** Token was created but expired

**Solution:** Check expiration date, create new token if expired

### ❌ Mistake 4: Wrong Account
**Problem:** Token belongs to different GitHub account

**Solution:** Make sure you're logged in as **j28045147-sys** when creating token

---

## 🚀 After Creating New Token

### Step 1: Copy the Token
Click the copy icon or select and copy the entire token

### Step 2: Run the Script Again
```
Double-click: run-push-website.bat
```

### Step 3: Enter Information
- Email: `j28045147@gmail.com`
- Method: `1`
- Token: **Paste the NEW token**

### Step 4: It Should Work Now!
You should see:
```
✅ Website successfully pushed to GitHub!
```

---

## 🔐 Verify Token Permissions

### Method 1: Check on GitHub
1. Go to: https://github.com/settings/tokens
2. Find your token
3. Click on it
4. Verify **`repo`** is checked

### Method 2: Test with API
```powershell
$token = "YOUR_NEW_TOKEN_HERE"
$headers = @{Authorization = "token $token"}
$response = Invoke-WebRequest -Uri "https://api.github.com/user" -Headers $headers
$scopes = $response.Headers['X-OAuth-Scopes']
Write-Host "Token scopes: $scopes"
```

Should show: `repo` in the output

---

## 📋 Step-by-Step Visual Guide

### Creating the Token:

```
1. Go to GitHub Settings
   ↓
2. Click "Developer settings" (bottom left)
   ↓
3. Click "Personal access tokens"
   ↓
4. Click "Tokens (classic)"
   ↓
5. Click "Generate new token" dropdown
   ↓
6. Select "Generate new token (classic)"
   ↓
7. Enter note: "Website Push Token"
   ↓
8. Select expiration: 90 days
   ↓
9. ✅ CHECK THE "repo" BOX ← MOST IMPORTANT!
   ↓
10. Scroll down, click "Generate token"
    ↓
11. COPY THE TOKEN IMMEDIATELY
    ↓
12. Save it somewhere safe
```

---

## 🎯 Quick Checklist

Before running the script again, verify:

- [ ] Logged into GitHub as **j28045147-sys**
- [ ] Created **Classic** token (not fine-grained)
- [ ] Checked **`repo`** scope
- [ ] Copied the token correctly
- [ ] Token hasn't expired
- [ ] No extra spaces when pasting token

---

## 🔄 Try Again

Once you have the new token with correct permissions:

1. **Run:** `run-push-website.bat`
2. **Enter email:** `j28045147@gmail.com`
3. **Choose:** `1`
4. **Paste:** Your NEW token
5. **Wait** for success message

---

## ✅ Expected Result

After using the correct token, you should see:

```
Testing repository access...
Repository is accessible
Pushing to main branch...
Successfully pushed to main branch!

==========================================
✅ Website successfully pushed to GitHub!
==========================================

View your repository at:
https://github.com/j28045147-sys/wedding-emergecy-website-
```

---

## 🐛 Still Getting 403 Error?

### Check These:

1. **Repository Exists?**
   - Go to: https://github.com/j28045147-sys/wedding-emergecy-website-
   - If 404, create the repository first

2. **Correct Account?**
   - Make sure token belongs to **j28045147-sys**
   - Not a different account

3. **Token Copied Correctly?**
   - No extra spaces
   - Complete token (all characters)
   - Not truncated

4. **Repository Settings?**
   - Check if repository has branch protection rules
   - Check if you're a collaborator (if it's someone else's repo)

---

## 📞 Alternative: Create Repository First

If the repository doesn't exist:

1. Go to: https://github.com/new
2. Login as **j28045147-sys**
3. Repository name: `wedding-emergecy-website-`
4. **Don't** initialize with README
5. Click "Create repository"
6. Then run the script again

---

## 🎉 Summary

**The issue:** Token doesn't have `repo` scope

**The fix:** Create new Classic token with `repo` scope checked

**Then:** Run the script again with the new token

---

**Create the new token now and try again!** 🚀

Link: https://github.com/settings/tokens
