#!/bin/bash
# NEXUS Data Layer — Create all collections in Directus
# Run: chmod +x setup-collections.sh && ./setup-collections.sh

set -e

URL="${DIRECTUS_URL:-http://localhost:8055}"
TOKEN="${DIRECTUS_TOKEN}"

if [ -z "$TOKEN" ]; then
  echo "ERROR: DIRECTUS_TOKEN not set. Run: source ~/.zshrc"
  exit 1
fi

H1="Authorization: Bearer $TOKEN"
H2="Content-Type: application/json"

echo "=== Creating NEXUS collections in Directus ==="
echo "URL: $URL"
echo ""

# --- 1. companies (create first, contacts references it) ---
echo "1/7 Creating companies..."
curl -s -X POST "$URL/collections" -H "$H1" -H "$H2" -d '{
  "collection": "companies",
  "meta": { "icon": "business", "note": "Client companies and organizations" },
  "fields": [
    { "field": "id", "type": "uuid", "meta": { "special": ["uuid"], "interface": "input", "readonly": true, "hidden": true }, "schema": { "is_primary_key": true, "has_auto_increment": false } },
    { "field": "name", "type": "string", "meta": { "interface": "input", "required": true, "width": "half" }, "schema": {} },
    { "field": "domain", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "industry", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "employees", "type": "integer", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "plan", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Free","value":"free"},{"text":"Starter","value":"starter"},{"text":"Pro","value":"pro"},{"text":"Enterprise","value":"enterprise"}] }, "width": "half" }, "schema": { "default_value": "free" } },
    { "field": "address", "type": "string", "meta": { "interface": "input", "width": "full" }, "schema": {} },
    { "field": "notes", "type": "text", "meta": { "interface": "input-multiline" }, "schema": {} }
  ]
}' > /dev/null && echo "  ✅ companies" || echo "  ❌ companies (may already exist)"

# --- 2. contacts ---
echo "2/7 Creating contacts..."
curl -s -X POST "$URL/collections" -H "$H1" -H "$H2" -d '{
  "collection": "contacts",
  "meta": { "icon": "people", "note": "People: leads, clients, and contacts" },
  "fields": [
    { "field": "id", "type": "uuid", "meta": { "special": ["uuid"], "interface": "input", "readonly": true, "hidden": true }, "schema": { "is_primary_key": true, "has_auto_increment": false } },
    { "field": "first_name", "type": "string", "meta": { "interface": "input", "required": true, "width": "half" }, "schema": {} },
    { "field": "last_name", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "email", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "phone", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "product", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Whabi","value":"whabi"},{"text":"Docflow","value":"docflow"},{"text":"Aurora","value":"aurora"}] }, "width": "half" }, "schema": {} },
    { "field": "lead_score", "type": "integer", "meta": { "interface": "input", "width": "half" }, "schema": { "default_value": 0 } },
    { "field": "status", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Lead","value":"lead"},{"text":"Client","value":"client"},{"text":"Churned","value":"churned"}] }, "width": "half" }, "schema": { "default_value": "lead" } },
    { "field": "source", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"WhatsApp","value":"whatsapp"},{"text":"Web","value":"web"},{"text":"Email","value":"email"},{"text":"Manual","value":"manual"}] }, "width": "half" }, "schema": { "default_value": "manual" } },
    { "field": "job_title", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "city", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "notes", "type": "text", "meta": { "interface": "input-multiline" }, "schema": {} }
  ]
}' > /dev/null && echo "  ✅ contacts" || echo "  ❌ contacts (may already exist)"

# --- 3. contacts → companies relationship ---
echo "   Adding company relationship to contacts..."
curl -s -X POST "$URL/fields/contacts" -H "$H1" -H "$H2" -d '{
  "field": "company",
  "type": "uuid",
  "meta": { "interface": "select-dropdown-m2o", "special": ["m2o"], "width": "half" },
  "schema": { "foreign_key_table": "companies", "foreign_key_column": "id" }
}' > /dev/null && echo "  ✅ contacts.company → companies" || echo "  ⚠️  relationship (may already exist)"

curl -s -X POST "$URL/relations" -H "$H1" -H "$H2" -d '{
  "collection": "contacts",
  "field": "company",
  "related_collection": "companies",
  "meta": { "one_field": "contacts" }
}' > /dev/null 2>&1

# --- 4. conversations ---
echo "3/7 Creating conversations..."
curl -s -X POST "$URL/collections" -H "$H1" -H "$H2" -d '{
  "collection": "conversations",
  "meta": { "icon": "chat", "note": "All interactions: WhatsApp, web chat, email" },
  "fields": [
    { "field": "id", "type": "uuid", "meta": { "special": ["uuid"], "interface": "input", "readonly": true, "hidden": true }, "schema": { "is_primary_key": true, "has_auto_increment": false } },
    { "field": "channel", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"WhatsApp","value":"whatsapp"},{"text":"Web","value":"web"},{"text":"Email","value":"email"}] }, "width": "half" }, "schema": { "default_value": "whatsapp" } },
    { "field": "direction", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Inbound","value":"inbound"},{"text":"Outbound","value":"outbound"}] }, "width": "half" }, "schema": { "default_value": "inbound" } },
    { "field": "raw_message", "type": "text", "meta": { "interface": "input-multiline", "note": "Original message from client" }, "schema": {} },
    { "field": "agent_response", "type": "text", "meta": { "interface": "input-multiline", "note": "Agent response" }, "schema": {} },
    { "field": "intent", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "sentiment", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Positive","value":"positive"},{"text":"Neutral","value":"neutral"},{"text":"Negative","value":"negative"}] }, "width": "half" }, "schema": { "default_value": "neutral" } },
    { "field": "lead_score", "type": "integer", "meta": { "interface": "input", "width": "half" }, "schema": { "default_value": 0 } },
    { "field": "agent_name", "type": "string", "meta": { "interface": "input", "width": "half", "note": "Which NEXUS agent handled this" }, "schema": {} }
  ]
}' > /dev/null && echo "  ✅ conversations" || echo "  ❌ conversations (may already exist)"

# conversations → contacts relationship
curl -s -X POST "$URL/fields/conversations" -H "$H1" -H "$H2" -d '{
  "field": "contact",
  "type": "uuid",
  "meta": { "interface": "select-dropdown-m2o", "special": ["m2o"], "width": "half" },
  "schema": { "foreign_key_table": "contacts", "foreign_key_column": "id" }
}' > /dev/null 2>&1
curl -s -X POST "$URL/relations" -H "$H1" -H "$H2" -d '{
  "collection": "conversations",
  "field": "contact",
  "related_collection": "contacts"
}' > /dev/null 2>&1
echo "  ✅ conversations.contact → contacts"

# --- 5. tickets ---
echo "4/7 Creating tickets..."
curl -s -X POST "$URL/collections" -H "$H1" -H "$H2" -d '{
  "collection": "tickets",
  "meta": { "icon": "confirmation_number", "note": "Support tickets" },
  "fields": [
    { "field": "id", "type": "uuid", "meta": { "special": ["uuid"], "interface": "input", "readonly": true, "hidden": true }, "schema": { "is_primary_key": true, "has_auto_increment": false } },
    { "field": "product", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Whabi","value":"whabi"},{"text":"Docflow","value":"docflow"},{"text":"Aurora","value":"aurora"}] }, "width": "half" }, "schema": {} },
    { "field": "intent", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "summary", "type": "text", "meta": { "interface": "input-multiline" }, "schema": {} },
    { "field": "resolution", "type": "text", "meta": { "interface": "input-multiline" }, "schema": {} },
    { "field": "urgency", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Low","value":"low"},{"text":"Medium","value":"medium"},{"text":"High","value":"high"}] }, "width": "half" }, "schema": { "default_value": "medium" } },
    { "field": "status", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Open","value":"open"},{"text":"Resolved","value":"resolved"},{"text":"Escalated","value":"escalated"}] }, "width": "half" }, "schema": { "default_value": "open" } }
  ]
}' > /dev/null && echo "  ✅ tickets" || echo "  ❌ tickets (may already exist)"

curl -s -X POST "$URL/fields/tickets" -H "$H1" -H "$H2" -d '{
  "field": "contact", "type": "uuid",
  "meta": { "interface": "select-dropdown-m2o", "special": ["m2o"], "width": "half" },
  "schema": { "foreign_key_table": "contacts", "foreign_key_column": "id" }
}' > /dev/null 2>&1
curl -s -X POST "$URL/relations" -H "$H1" -H "$H2" -d '{"collection":"tickets","field":"contact","related_collection":"contacts"}' > /dev/null 2>&1

# --- 6. payments ---
echo "5/7 Creating payments..."
curl -s -X POST "$URL/collections" -H "$H1" -H "$H2" -d '{
  "collection": "payments",
  "meta": { "icon": "payments", "note": "Payment records" },
  "fields": [
    { "field": "id", "type": "uuid", "meta": { "special": ["uuid"], "interface": "input", "readonly": true, "hidden": true }, "schema": { "is_primary_key": true, "has_auto_increment": false } },
    { "field": "amount", "type": "float", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "method", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "reference", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "status", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Pending","value":"pending"},{"text":"Approved","value":"approved"},{"text":"Rejected","value":"rejected"}] }, "width": "half" }, "schema": { "default_value": "pending" } },
    { "field": "approved_by", "type": "string", "meta": { "interface": "input", "width": "half" }, "schema": {} },
    { "field": "product", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Whabi","value":"whabi"},{"text":"Docflow","value":"docflow"},{"text":"Aurora","value":"aurora"}] }, "width": "half" }, "schema": {} }
  ]
}' > /dev/null && echo "  ✅ payments" || echo "  ❌ payments (may already exist)"

curl -s -X POST "$URL/fields/payments" -H "$H1" -H "$H2" -d '{"field":"contact","type":"uuid","meta":{"interface":"select-dropdown-m2o","special":["m2o"],"width":"half"},"schema":{"foreign_key_table":"contacts","foreign_key_column":"id"}}' > /dev/null 2>&1
curl -s -X POST "$URL/relations" -H "$H1" -H "$H2" -d '{"collection":"payments","field":"contact","related_collection":"contacts"}' > /dev/null 2>&1
curl -s -X POST "$URL/fields/payments" -H "$H1" -H "$H2" -d '{"field":"company","type":"uuid","meta":{"interface":"select-dropdown-m2o","special":["m2o"],"width":"half"},"schema":{"foreign_key_table":"companies","foreign_key_column":"id"}}' > /dev/null 2>&1
curl -s -X POST "$URL/relations" -H "$H1" -H "$H2" -d '{"collection":"payments","field":"company","related_collection":"companies"}' > /dev/null 2>&1

# --- 7. tasks ---
echo "6/7 Creating tasks..."
curl -s -X POST "$URL/collections" -H "$H1" -H "$H2" -d '{
  "collection": "tasks",
  "meta": { "icon": "task_alt", "note": "Follow-ups and action items" },
  "fields": [
    { "field": "id", "type": "uuid", "meta": { "special": ["uuid"], "interface": "input", "readonly": true, "hidden": true }, "schema": { "is_primary_key": true, "has_auto_increment": false } },
    { "field": "title", "type": "string", "meta": { "interface": "input", "required": true, "width": "full" }, "schema": {} },
    { "field": "body", "type": "text", "meta": { "interface": "input-multiline" }, "schema": {} },
    { "field": "status", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"To Do","value":"todo"},{"text":"In Progress","value":"in_progress"},{"text":"Done","value":"done"}] }, "width": "half" }, "schema": { "default_value": "todo" } },
    { "field": "due_date", "type": "timestamp", "meta": { "interface": "datetime", "width": "half" }, "schema": {} },
    { "field": "source", "type": "string", "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Auto","value":"auto"},{"text":"Manual","value":"manual"}] }, "width": "half" }, "schema": { "default_value": "auto" } }
  ]
}' > /dev/null && echo "  ✅ tasks" || echo "  ❌ tasks (may already exist)"

curl -s -X POST "$URL/fields/tasks" -H "$H1" -H "$H2" -d '{"field":"contact","type":"uuid","meta":{"interface":"select-dropdown-m2o","special":["m2o"],"width":"half"},"schema":{"foreign_key_table":"contacts","foreign_key_column":"id"}}' > /dev/null 2>&1
curl -s -X POST "$URL/relations" -H "$H1" -H "$H2" -d '{"collection":"tasks","field":"contact","related_collection":"contacts"}' > /dev/null 2>&1

# --- 8. events ---
echo "7/7 Creating events..."
curl -s -X POST "$URL/collections" -H "$H1" -H "$H2" -d '{
  "collection": "events",
  "meta": { "icon": "electric_bolt", "note": "Raw event log — audit trail for everything" },
  "fields": [
    { "field": "id", "type": "uuid", "meta": { "special": ["uuid"], "interface": "input", "readonly": true, "hidden": true }, "schema": { "is_primary_key": true, "has_auto_increment": false } },
    { "field": "type", "type": "string", "meta": { "interface": "input", "required": true, "width": "half", "note": "whatsapp, email, payment, ticket, login, etc." }, "schema": {} },
    { "field": "payload", "type": "json", "meta": { "interface": "input-code", "options": { "language": "json" }, "note": "Raw event data" }, "schema": {} }
  ]
}' > /dev/null && echo "  ✅ events" || echo "  ❌ events (may already exist)"

curl -s -X POST "$URL/fields/events" -H "$H1" -H "$H2" -d '{"field":"contact","type":"uuid","meta":{"interface":"select-dropdown-m2o","special":["m2o"],"width":"half"},"schema":{"foreign_key_table":"contacts","foreign_key_column":"id"}}' > /dev/null 2>&1
curl -s -X POST "$URL/relations" -H "$H1" -H "$H2" -d '{"collection":"events","field":"contact","related_collection":"contacts"}' > /dev/null 2>&1

echo ""
echo "=== Done! ==="
echo "Open http://localhost:8055 to see your collections."
echo ""
echo "Collections created:"
echo "  📋 companies    — Client companies"
echo "  👤 contacts     — People (leads, clients)"
echo "  💬 conversations — WhatsApp/chat/email interactions"
echo "  🎫 tickets      — Support tickets"
echo "  💰 payments     — Payment records"
echo "  ✅ tasks        — Follow-ups and actions"
echo "  ⚡ events       — Raw event log (audit trail)"
echo ""
echo "Relationships:"
echo "  contacts.company → companies"
echo "  conversations.contact → contacts"
echo "  tickets.contact → contacts"
echo "  payments.contact → contacts"
echo "  payments.company → companies"
echo "  tasks.contact → contacts"
echo "  events.contact → contacts"
