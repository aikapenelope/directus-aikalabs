# Directus MCP Setup Guide

Step-by-step guide to configure Directus for AI agent access via MCP.

## Step 1: Create a Dedicated MCP Role

**Do NOT use the admin account for MCP.** Create a dedicated role:

1. Open http://localhost:8055
2. Go to **Settings** (gear icon) → **Access Control** → **Roles**
3. Click **+ Create Role**
4. Name: `MCP Agent`
5. Description: `AI agent access for NEXUS`

### Configure Permissions for the MCP Agent Role

For each custom collection (contacts, companies, conversations, tickets, payments, tasks, events):

1. Click on the `MCP Agent` role
2. Find each collection in the permissions list
3. Set permissions:

| Collection | Create | Read | Update | Delete |
|-----------|--------|------|--------|--------|
| contacts | ✅ All | ✅ All | ✅ All | ❌ No |
| companies | ✅ All | ✅ All | ✅ All | ❌ No |
| conversations | ✅ All | ✅ All | ✅ All | ❌ No |
| tickets | ✅ All | ✅ All | ✅ All | ❌ No |
| payments | ✅ All | ✅ All | ✅ All | ❌ No |
| tasks | ✅ All | ✅ All | ✅ All | ❌ No |
| events | ✅ All | ✅ All | ✅ All | ❌ No |
| directus_files | ❌ No | ✅ All | ❌ No | ❌ No |

**Important:** Click the checkmark icon for each permission to set it to "All Access" (not custom).

Delete is disabled to prevent accidental data loss from AI agents.

## Step 2: Create a Dedicated MCP User

1. Go to **User Directory** (people icon in sidebar)
2. Click **+ Create User**
3. Fill in:
   - First Name: `NEXUS`
   - Last Name: `MCP Agent`
   - Email: `mcp@aikalabs.com`
   - Password: (set any password)
   - Role: Select **MCP Agent** (the role you just created)
4. Scroll down to the **Token** field
5. Click **Generate** → copy the token
6. **Click Save** (if you don't save, the token won't work!)

## Step 3: Configure Environment Variables

Add to your `~/.zshrc`:

```bash
export DIRECTUS_URL="http://localhost:8055"
export DIRECTUS_TOKEN="paste-the-token-from-step-2"
```

Then:

```bash
source ~/.zshrc
```

## Step 4: Verify the Connection

Test that the token can access your collections:

```bash
# Should return your custom collections
curl -s -H "Authorization: Bearer $DIRECTUS_TOKEN" "$DIRECTUS_URL/items/contacts" | head -20

# Should return empty data (no contacts yet)
# If you get 403 Forbidden, the permissions are not set correctly
```

If you get `403 Forbidden`:
- Go back to Settings → Access Control → MCP Agent role
- Make sure each collection has Read permission set to "All Access"
- The permission icon should be a full green checkmark, not a partial one

## Step 5: Test MCP Server

```bash
# This should start without errors
DIRECTUS_URL="$DIRECTUS_URL" DIRECTUS_TOKEN="$DIRECTUS_TOKEN" npx @directus/content-mcp@latest
```

You should see the MCP server start on stdio. Press Ctrl+C to stop.

## Step 6: Restart nexus.py

```bash
source ~/.zshrc
cd ~/Agno
python nexus.py
```

You should see in the logs:
```
N8N Workflow Builder MCP server running on stdio
@directus/content-mcp running on stdio
```

## Troubleshooting

### "No prompts collection configured"
This is normal. It's an optional feature. Ignore this message.

### MCP can't see custom collections
The MCP user's role doesn't have permissions for those collections.
Fix: Settings → Access Control → MCP Agent → add permissions for each collection.

### 403 Forbidden on /items/contacts
The token belongs to a user without read access to the contacts collection.
Fix: Check that the user's role has Read: All Access for contacts.

### 401 Unauthorized
The token is invalid or expired.
Fix: Go to User Directory → MCP user → regenerate token → Save.

### Agent creates records but MCP can't read them
The direct tools (save_contact, etc.) use the DIRECTUS_TOKEN.
The MCP also uses DIRECTUS_TOKEN.
Both must use the same token, and that token's role must have both Create and Read permissions.

### Collections don't appear in read-collections
Only collections with Read permission for the current user appear.
Fix: Add Read: All Access for each collection in the MCP Agent role.

## References

- [Directus MCP Security Guide](https://directus.io/docs/guides/ai/mcp/security)
- [Directus MCP Tools](https://directus.io/docs/guides/ai/mcp/tools)
- [Directus Access Control](https://docs.directus.io/configuration/users-roles-permissions.html)
- [Directus Content MCP repo](https://github.com/directus/mcp)
