# Directus — NEXUS Data Layer

Data infrastructure for the NEXUS multi-agent system. Replaces Twenty CRM with a complete data platform: CRM, conversations, events, knowledge base, and automation flows.

## What this is

- **Directus** — headless CMS with admin UI, REST/GraphQL API, and MCP server
- **PostgreSQL 16** — source of truth for all business data
- **MCP Server** — official Directus MCP (`@directus/content-mcp`) for AI agent access

## Quick Start

```bash
# 1. Clone
git clone https://github.com/aikapenelope/directus-aikalabs.git
cd directus-aikalabs

# 2. Start
docker compose up -d

# 3. Wait ~30 seconds, then open
open http://localhost:8055
```

Login: `admin@aikalabs.com` / `admin123`

## Ports

| Port | Service |
|------|---------|
| 8055 | Directus (admin UI + API + MCP) |
| 5432 | PostgreSQL |

## Connect to NEXUS (Agno)

### 1. Generate a Directus token

1. Open http://localhost:8055
2. Go to User Directory → your user
3. Scroll to **Token** field → Generate → Copy
4. Click **Save** (important!)

### 2. Add to ~/.zshrc

```bash
export DIRECTUS_URL="http://localhost:8055"
export DIRECTUS_TOKEN="your-token-here"
```

### 3. MCP in nexus.py

```python
MCPTools(
    command="npx @directus/content-mcp@latest",
    env={
        "DIRECTUS_URL": os.getenv("DIRECTUS_URL", "http://localhost:8055"),
        "DIRECTUS_TOKEN": os.getenv("DIRECTUS_TOKEN", ""),
    },
)
```

## MCP Tools Available

The Directus MCP server provides 20 tools:

| Tool | Description |
|------|-------------|
| `system-prompt` | Load Directus context for the AI |
| `users-me` | Get current user info |
| `read-collections` | List all collections (tables) |
| `read-items` | Query items from any collection |
| `create-item` | Create new records |
| `update-item` | Update existing records |
| `delete-item` | Remove records |
| `read-files` | Access file metadata |
| `import-file` | Import files from URLs |
| `update-files` | Update file metadata |
| `read-fields` | Get field definitions |
| `read-field` | Get specific field info |
| `create-field` | Add new fields |
| `update-field` | Modify fields |
| `read-flows` | List automation flows |
| `trigger-flow` | Execute flows programmatically |
| `read-comments` | View comments on items |
| `upsert-comment` | Add/update comments |
| `markdown-tool` | Convert markdown ↔ HTML |
| `get-prompts` | List stored AI prompts |

Source: [directus/mcp](https://github.com/directus/mcp)

## Data Schema

Create these collections in Directus for the NEXUS system:

### contacts
| Field | Type | Description |
|-------|------|-------------|
| first_name | String | First name |
| last_name | String | Last name |
| email | String | Email address |
| phone | String | Phone number |
| company | M2O → companies | Linked company |
| product | Dropdown | whabi / docflow / aurora |
| lead_score | Integer | 1-10 |
| status | Dropdown | lead / client / churned |
| source | Dropdown | whatsapp / web / email / manual |

### companies
| Field | Type | Description |
|-------|------|-------------|
| name | String | Company name |
| domain | String | Website |
| industry | String | Industry |
| employees | Integer | Employee count |
| plan | Dropdown | free / starter / pro / enterprise |

### conversations
| Field | Type | Description |
|-------|------|-------------|
| contact | M2O → contacts | Who |
| channel | Dropdown | whatsapp / web / email |
| direction | Dropdown | inbound / outbound |
| raw_message | Text | Original message |
| agent_response | Text | Agent's response |
| intent | String | pricing / support / complaint / info |
| sentiment | Dropdown | positive / neutral / negative |
| lead_score | Integer | Score from this interaction |

### tickets
| Field | Type | Description |
|-------|------|-------------|
| contact | M2O → contacts | Who |
| product | Dropdown | whabi / docflow / aurora |
| intent | String | What they needed |
| summary | Text | Summary |
| resolution | Text | How it was resolved |
| urgency | Dropdown | low / medium / high |
| status | Dropdown | open / resolved / escalated |

### payments
| Field | Type | Description |
|-------|------|-------------|
| contact | M2O → contacts | Who paid |
| company | M2O → companies | Which company |
| amount | Float | Amount |
| method | String | Payment method |
| reference | String | Reference number |
| status | Dropdown | pending / approved / rejected |
| approved_by | String | Who approved |

### tasks
| Field | Type | Description |
|-------|------|-------------|
| contact | M2O → contacts | Related contact |
| title | String | Task title |
| body | Text | Description |
| status | Dropdown | todo / in_progress / done |
| due_date | DateTime | When |
| source | Dropdown | auto / manual |

### events
| Field | Type | Description |
|-------|------|-------------|
| type | String | whatsapp / email / payment / ticket / login |
| payload | JSON | Raw event data |
| contact | M2O → contacts | Related contact (nullable) |

## Architecture

```
nexus-ui (localhost:3001)
    │
    ├── Directus REST API (localhost:8055/items/*)
    │
AgentOS (localhost:7777)
    │
    ├── Directus MCP (@directus/content-mcp)
    │       ├── read-items, create-item, update-item
    │       ├── read-collections, read-fields
    │       ├── trigger-flow (automations)
    │       └── 20 tools total
    │
    └── Direct REST API (for pre/post hooks, 0 tokens)
            └── POST http://localhost:8055/items/events
```

## Compatibility

The data lives in PostgreSQL, accessible via:
- **Directus MCP** — for Agno, Mastra, or any MCP-compatible framework
- **Directus REST API** — for any HTTP client (nexus-ui, mobile apps)
- **Directus GraphQL** — for complex queries
- **PostgreSQL direct** — for any framework with a DB driver

If you migrate from Agno to Mastra or LangChain, the data stays.

## Roadmap

### Phase 1: Setup (this PR) ✅
- [x] Docker Compose (Directus 11 + PostgreSQL 16)
- [x] Environment configuration
- [x] Documentation and schema design

### Phase 2: Schema & Collections
- [ ] Create 7 collections in Directus (contacts, companies, conversations, tickets, payments, tasks, events)
- [ ] Configure field types, dropdowns, and relationships (M2O)
- [ ] Set up Kanban views for tickets and tasks
- [ ] Create MCP user with scoped permissions

### Phase 3: Connect Agno
- [ ] Replace Twenty MCP with Directus MCP in nexus.py
- [ ] Update support agent tools to use Directus `create-item`
- [ ] Update nexus-ui `/crm` page to read from Directus REST API
- [ ] Remove Twenty dependencies from Agno repo

### Phase 4: Automations (Directus Flows)
- [ ] Flow: WhatsApp incoming → auto-log in events collection (0 tokens)
- [ ] Flow: WhatsApp incoming → auto-create/update contact (0 tokens)
- [ ] Flow: High lead score → create follow-up task
- [ ] Flow: Payment approved → notify via webhook
- [ ] Flow: Ticket escalated → alert team

### Phase 5: Analytics & Optimization
- [ ] Batch daily digest (1 LLM call/day for conversation analysis)
- [ ] Dashboard metrics from events collection
- [ ] Knowledge base integration (learned solutions → Directus)
- [ ] Backup schedule (pg_dump)

### Phase 6: Multi-framework Compatibility
- [ ] Test Directus MCP with Mastra
- [ ] Document REST API patterns for framework-agnostic access
- [ ] pgvector extension for RAG directly in PostgreSQL

## References

- [Directus Docs](https://docs.directus.io)
- [Directus MCP Server](https://github.com/directus/mcp)
- [Directus Docker Guide](https://docs.directus.io/self-hosted/docker-guide.html)
- [Directus MCP Tools](https://directus.io/docs/guides/ai/mcp/tools)
