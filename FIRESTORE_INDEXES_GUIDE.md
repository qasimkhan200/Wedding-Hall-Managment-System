# Firestore Indexes Guide

## Why You Need Indexes

Firestore requires indexes for queries that:
- Filter by one field AND sort by another field
- Filter by multiple fields
- Use array-contains with other filters

Without indexes, these queries will fail with `FAILED_PRECONDITION` error.

## Required Indexes for Your App

### 1. Vendor Orders Query ⚠️ (Currently Failing)
**Collection:** `orders`
**Fields:**
- `vendorId` - Ascending
- `createdAt` - Descending

**Why:** Vendors need to see their orders sorted by newest first

**Create:** Click the link in the error message, or:
https://console.firebase.google.com/project/orginize-app/firestore/indexes

---

### 2. Host Orders Query
**Collection:** `orders`
**Fields:**
- `hostId` - Ascending
- `createdAt` - Descending

**Why:** Hosts need to see their orders sorted by newest first

---

### 3. Rider Orders Query
**Collection:** `orders`
**Fields:**
- `riderId` - Ascending
- `createdAt` - Descending

**Why:** Riders need to see their deliveries sorted by newest first

---

### 4. Vendor Items Query
**Collection:** `items`
**Fields:**
- `vendorId` - Ascending
- `createdAt` - Descending

**Why:** Vendors need to see their inventory sorted by newest first

---

### 5. Items by Category Query
**Collection:** `items`
**Fields:**
- `category` - Ascending
- `isAvailable` - Ascending
- `createdAt` - Descending

**Why:** Hosts browse items by category, showing only available items

---

## How to Create Indexes

### Method 1: Click Error Links (Easiest)
When you see a `FAILED_PRECONDITION` error:
1. Look for the URL in the error message
2. Click the URL (or copy-paste into browser)
3. Firebase Console will open with the index pre-configured
4. Click "Create Index"
5. Wait 1-2 minutes for it to build

### Method 2: Create Manually
1. Go to: https://console.firebase.google.com/project/orginize-app/firestore/indexes
2. Click "Create Index"
3. Select Collection
4. Add Fields (in order)
5. Set Ascending/Descending for each field
6. Click "Create"

### Method 3: Use Firebase CLI (Advanced)
Create a file `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "hostId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "riderId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "isAvailable", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

Then run:
```bash
firebase deploy --only firestore:indexes
```

## Index Building Time

- Simple indexes: 1-2 minutes
- Complex indexes: 2-5 minutes
- Large collections: 5-10 minutes

You'll see "Building" status in Firebase Console. Once it shows "Enabled", the query will work.

## Testing After Index Creation

1. Wait for index to finish building
2. Restart your app (or hot reload)
3. Navigate to the screen that was failing
4. The data should load successfully!

## Common Issues

### "Index already exists"
- The index is already created
- Wait for it to finish building
- Check the "Indexes" tab in Firebase Console

### "Query still failing after index created"
- Index might still be building (check console)
- Try restarting the app
- Verify the index fields match your query exactly

### "Too many indexes"
- Firestore has a limit of 200 composite indexes per project
- You're nowhere near that limit with these 5 indexes

## Summary

**Immediate Action Required:**
1. Click the link in the error message to create the vendor orders index
2. Wait 1-2 minutes for it to build
3. Restart your app

**Recommended:**
Create all 5 indexes listed above to prevent future errors as you test different features.

**Total Setup Time:** ~10 minutes (indexes build in parallel)

Once indexes are created, your app will work perfectly! 🚀
