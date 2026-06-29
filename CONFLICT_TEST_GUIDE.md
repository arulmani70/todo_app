# Conflict Resolution — Test Guide

Covers two scenarios:
- **Scenario A** — Standard conflict: note edited both locally & on server
- **Scenario B** — Server-deleted note: note deleted from server while app is offline

---

## Prerequisites

- App running on a device/emulator
- PowerShell terminal (comes with Windows)
- Internet connection (will be toggled off/on)

---

## Scenario A — Standard Conflict (Both Local & Server Modified)

### Step 1: Create a note while online

1. Launch the app (internet ON)
2. Tap **+** FAB
3. **Title:** `Conflict Test`
4. **Body:** `Original content`
5. Tap **Create Note**
6. Wait for green **Synced** badge

### Step 2: Find its remote ID

```powershell
Invoke-RestMethod -Method Get -Uri "https://6a4204947602860e6520abd5.mockapi.io/notes" | ConvertTo-Json -Depth 3
```

Find your note in the output. Note its `"id"` value (e.g., `"3"`). Keep this window open.

### Step 3: Go offline

Toggle airplane mode or disconnect WiFi.

### Step 4: Edit the note locally

1. Tap the note in the list
2. Change body to: `Local edit while offline`
3. Tap **Update Note**
4. Note shows orange **Pending Sync** badge

### Step 5: Edit the same note on the server directly

While still offline on the app, run this to simulate another device editing:

```powershell
$noteId = "3"   # ← use actual ID from Step 2
$body = @{
    title = "Conflict Test"
    body = "Server edit from another device"
    updatedAt = (Get-Date -Format "o")
} | ConvertTo-Json

Invoke-RestMethod -Method Put -Uri "https://6a4204947602860e6520abd5.mockapi.io/notes/$noteId" -Body $body -ContentType "application/json"
```

### Step 6: Come back online

Turn internet back ON. Background sync triggers after ~2s.

### ✅ Expected Result

- Note shows a red **Conflict** badge
- Conflict dialog pops up automatically

```
┌─────────────────────────────────────┐
│  ⚠ Conflict Detected                │
│                                      │
│  Local:  "Local edit while offline"  │
│  vs                                  │
│  Server: "Server edit from another"  │
│                                      │
│  [Keep Local]    [Keep Server]       │
└─────────────────────────────────────┘
```

### Step 7: Resolve

- **Keep Local** → your edit overwrites server
- **Keep Server** → server edit overwrites local
- Note returns to green **Synced**

---

## Scenario B — Server-Deleted Note

Tests that a note deleted from the server is also removed locally.

### Step 1: Create a note while online

1. App internet ON
2. Tap **+** FAB
3. **Title:** `Will be deleted from server`
4. **Body:** `This note will be deleted remotely`
5. Tap **Create Note**
6. Wait for green **Synced** badge

### Step 2: Find its remote ID

```powershell
Invoke-RestMethod -Method Get -Uri "https://6a4204947602860e6520abd5.mockapi.io/notes" | ConvertTo-Json -Depth 3
```

Note the `"id"`.

### Step 3: Delete the note from the server directly

```powershell
$noteId = "4"   # ← use actual ID
Invoke-RestMethod -Method Delete -Uri "https://6a4204947602860e6520abd5.mockapi.io/notes/$noteId"
```

Verify it's gone:

```powershell
Invoke-RestMethod -Method Get -Uri "https://6a4204947602860e6520abd5.mockapi.io/notes"
```

The list should be shorter now.

### Step 4: Trigger a sync in the app

**Option A:** Tap the **Sync** (↻) button in the app bar
**Option B:** Toggle airplane mode off→on to trigger auto-sync

### ✅ Expected Result

- The note disappears from the list
- It was permanently deleted from local SQLite during `_pullRemoteChanges()`
- No conflict dialog — since the note was `synced` (no local pending changes), it's silently removed

### Recovery if you want to keep a local copy

If you had modified the note locally (orange **Pending Sync**) before the server deletion, the app **will not** auto-delete it — it stays as `pending_sync` and the push phase will retry sending it to the server on the next sync.

---

## Quick Reference

| Scenario | Local state | Server state | Result |
|----------|-------------|-------------|--------|
| Both edited | `pending_sync` | newer `updatedAt` | ⚠ Conflict — user picks |
| Server deletes synced note | `synced` | missing from GET | ✅ Silently deleted locally |
| Server deletes pending note | `pending_sync` | missing from GET | ⏳ Stays pending, retries push |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No conflict after reconnect | Wait 5s or tap Sync button |
| Conflict dialog doesn't auto-open | Tap note → ⋮ → Resolve Conflict |
| API returns 404 | Run GET to find the correct note id |
| Note still pending after sync | Server timestamp may not be newer — run Step 5 again with fresh timestamp |
| Test notes cluttering the list | Run `Invoke-RestMethod -Method Get ...` to list all, then DELETE each `id` |
