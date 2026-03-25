# Directus — NEXUS Data Layer

Data infrastructure for the NEXUS multi-agent system (AikaLabs). CRM, conversations, events, knowledge base, and automation flows — all in one platform with AI agent access via MCP.

## Quick Start

```bash
git clone https://github.com/aikapenelope/directus-aikalabs.git
cd directus-aikalabs
cp .env.example .env        # Edit with your credentials
docker compose up -d         # Wait ~30 seconds
open http://localhost:8055   # Login with your admin credentials
```

## Ports

| Port | Service |
|------|---------|
| 3001 | nexus-ui (Next.js dashboard) |
| 7777 | AgentOS (Agno agents) |
| 8055 | Directus (admin UI + API + MCP) |
| 5432 | PostgreSQL |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│           BUSINESS DATA (permanent, yours)           │
│                                                      │
│  Directus + PostgreSQL (localhost:8055)               │
│  ├── contacts, companies         (CRM)               │
│  ├── conversations               (WhatsApp/chat log) │
│  ├── tickets, payments, tasks    (operations)        │
│  ├── events                      (raw audit trail)   │
│  └── knowledge_items             (solutions/patterns) │
│                                                      │
│  Access: MCP · REST API · GraphQL · SQL direct       │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│           AI LAYER (replaceable)                     │
│                                                      │
│  Agno / Mastra / LangChain (localhost:7777)          │
│  ├── Sessions, traces        (framework-specific)    │
│  ├── Vectors/embeddings      (LanceDB / pgvector)    │
│  └── Agents, teams, workflows                        │
│                                                      │
│  If you switch frameworks, business data stays.      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│           FRONTEND (localhost:3001)                   │
│                                                      │
│  nexus-ui reads from both:                           │
│  ├── Directus REST API → CRM, analytics, dashboard   │
│  └── AgentOS REST API  → agents, teams, chat         │
└─────────────────────────────────────────────────────┘
```

## Data Flow: WhatsApp → Directus (0 tokens)

```
WhatsApp message arrives
    │
    ▼
Agno pre_hook (Python, 0 tokens):
    ├── POST directus/items/events      (raw log)
    └── POST directus/items/contacts    (upsert by phone)
    │
    ▼
Agent responds (tokens — MiniMax/OpenAI):
    └── Reads client context via MCP (read-items contacts)
    │
    ▼
Agno post_hook (Python, 0 tokens):
    ├── POST directus/items/conversations (message + response)
    └── POST directus/items/tickets       (if support interaction)
    │
    ▼
nexus-ui reads from Directus REST API to display in dashboard
```

## MCP Integration with Agno

### 1. Generate a Directus token

1. Open http://localhost:8055
2. User Directory → your user → scroll to **Token** → Generate → Copy
3. **Save the user** (important!)

### 2. Add to ~/.zshrc

```bash
export DIRECTUS_URL="http://localhost:8055"
export DIRECTUS_TOKEN="your-token-here"
```

### 3. In nexus.py

```python
from agno.tools.mcp import MCPTools

MCPTools(
    command="npx @directus/content-mcp@latest",
    env={
        "DIRECTUS_URL": os.getenv("DIRECTUS_URL", "http://localhost:8055"),
        "DIRECTUS_TOKEN": os.getenv("DIRECTUS_TOKEN", ""),
    },
)
```

## MCP Tools (20 total)

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

## Roadmap

### Phase 1: Setup ✅
- [x] Docker Compose (Directus 11 + PostgreSQL 16)
- [x] Environment configuration (.env, no credentials in repo)
- [x] Documentation, schema design, architecture

### Phase 2: Schema & Collections
- [ ] Create 7 collections in Directus UI (contacts, companies, conversations, tickets, payments, tasks, events)
- [ ] Configure field types, dropdowns, and M2O relationships
- [ ] Set up Kanban views for tickets (open → resolved → escalated) and tasks (todo → in_progress → done)
- [ ] Create dedicated MCP user with scoped permissions (read/write items, no admin)
- [ ] Generate static token for MCP access

### Phase 3: Connect Agno → Directus
- [ ] Replace Twenty MCP with Directus MCP (`@directus/content-mcp`) in nexus.py
- [ ] Add pre_hook: auto-log WhatsApp messages to events collection (0 tokens)
- [ ] Add pre_hook: auto-create/update contact by phone number (0 tokens)
- [ ] Add post_hook: save conversation (raw_message + agent_response + intent) (0 tokens)
- [ ] Update support agent tools to use Directus `create-item` via MCP
- [ ] Remove Twenty dependencies, tools, and skills from Agno repo

### Phase 4: Connect nexus-ui → Directus
- [ ] Replace `lib/twenty.ts` with `lib/directus.ts` (REST API client)
- [ ] Update `/crm` page to read contacts, companies, tasks, notes from Directus
- [ ] Add conversation history view (all WhatsApp/chat interactions per contact)
- [ ] Dashboard stats from Directus (total contacts, conversations today, open tickets)
- [ ] Remove NEXT_PUBLIC_TWENTY_* environment variables

### Phase 5: Automations (Directus Flows)
- [ ] Flow: WhatsApp incoming → auto-log in events (webhook trigger, 0 tokens)
- [ ] Flow: New contact created → assign default lead_score and status
- [ ] Flow: lead_score >= 7 → auto-create follow-up task
- [ ] Flow: Payment status → approved → send webhook notification
- [ ] Flow: Ticket escalated → create urgent task + notify team
- [ ] Flow: Daily schedule → export conversation summary (batch, 1 LLM call/day)

### Phase 6: Analytics & Knowledge
- [ ] Batch daily digest: analyze all conversations from yesterday (1 LLM call)
- [ ] Dashboard metrics: conversations/day, avg response time, lead conversion rate
- [ ] Knowledge base sync: agent learned_knowledge → Directus knowledge_items collection
- [ ] Backup schedule: pg_dump daily to local folder
- [ ] Sentiment trends over time (from conversations collection)

### Phase 7: Multi-framework & Scale
- [ ] Test Directus MCP with Mastra framework
- [ ] pgvector extension in PostgreSQL (move vectors from LanceDB)
- [ ] Document REST API patterns for framework-agnostic access
- [ ] Rate limiting and API key rotation for production
- [ ] Multi-user roles (admin, support agent, viewer)

## Compatibility

Data lives in PostgreSQL, accessible via:
- **Directus MCP** — Agno, Mastra, or any MCP-compatible framework
- **Directus REST API** — any HTTP client (nexus-ui, mobile apps, Zapier)
- **Directus GraphQL** — complex relational queries
- **PostgreSQL direct** — any framework with a DB driver (SQLAlchemy, Prisma, etc.)

## References

- [Directus Docs](https://docs.directus.io)
- [Directus MCP Server](https://github.com/directus/mcp)
- [Directus MCP Tools](https://directus.io/docs/guides/ai/mcp/tools)
- [Directus Docker Guide](https://docs.directus.io/self-hosted/docker-guide.html)
- [Directus Flows](https://docs.directus.io/app/flows.html)
