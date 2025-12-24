# Gmail Club Mail Automation Agent (Single-Agent Playbook)

## Objective
This agent is responsible for building and maintaining a **fully automated Gmail → Google Form extraction system** for club mails sent from:

```
asstdir.cac@vitap.ac.in
```

The system must work **without manual interaction** after initial authorization.

---

## End-to-End System Flow

1. One-time OAuth authorization
2. Gmail Watch registration
3. Gmail sends change events via Pub/Sub
4. FastAPI receives Pub/Sub push
5. Agent fetches new emails using Gmail history
6. Agent filters club mails
7. Agent extracts Google Form links
8. Agent stores / exposes results

This is an **event-driven pipeline**.

---

## Agent Responsibilities (All-in-One)

### 1. OAuth & Credential Persistence
- Perform OAuth once
- Store access_token, refresh_token, expiry securely
- Auto-refresh tokens
- No repeated OAuth UI

### 2. Gmail Watch Management
- Call users.watch
- Store historyId and expiration
- Renew watch before expiry

### 3. Pub/Sub Infrastructure
- Create topic: gmail-club-topic
- Grant publisher role to gmail-api-push@system.gserviceaccount.com
- Create push subscription to POST /pubsub/gmail

### 4. Pub/Sub Push Receiver
- Receive POST events
- Decode Base64 payload
- Extract historyId
- Always ACK

### 5. Gmail History Processing
- Use users.history.list
- Fetch messageAdded only
- Update baseline historyId

### 6. Email Filtering
- Fetch full message
- Accept ONLY sender: asstdir.cac@vitap.ac.in

### 7. Google Form Extraction
- Extract links from:
  - docs.google.com/forms
  - forms.gle
- Deduplicate links

### 8. Idempotency & Storage
- Store processed message IDs
- Prevent duplicates
- Persist form links

---

## Non-Negotiable Rules

- No inbox polling
- No scanning last N emails
- No repeated OAuth
- No hardcoded secrets
- Event-driven only

---

## Deployment Notes

- HTTPS required
- ngrok allowed for local testing
- Watch renewal must survive restarts

---

## Definition of Done

- OAuth completed once
- Gmail watch active
- Pub/Sub pushes received
- Club mail detected automatically
- Google Form links extracted
- Zero manual intervention
