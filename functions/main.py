import os
import json
import base64
import re
from firebase_functions import pubsub_fn, options
from firebase_admin import initialize_app, firestore
import google.oauth2.credentials
from googleapiclient.discovery import build

initialize_app()
db = firestore.client()

# Constants
OFFICIAL_CLUB_SENDERS = {"asstdir.cac@vitap.ac.in", "codered@vitap.ac.in"}
GOOGLE_FORM_REGEX = re.compile(r"(https://docs\.google\.com/forms/[^\s<>]+|https://forms\.gle/[^\s<>]+)")
VENUE_REGEX = re.compile(r"(?i)venue\s*[:\-]\s*([^\n\r]+)")
DATE_REGEX = re.compile(r"(?i)date\s*[:\-]\s*([^\n\r]+)")
TIME_REGEX = re.compile(r"(?i)time\s*[:\-]\s*([^\n\r]+)")

def _decode_base64url(data: str) -> str:
    if not data: return ""
    return base64.urlsafe_b64decode(data + "===").decode("utf-8", errors="ignore")

def extract_email_body(payload: dict) -> str:
    if "parts" in payload:
        for part in payload["parts"]:
            mime_type = part.get("mimeType", "")
            body = part.get("body", {})
            if mime_type in ["text/plain", "text/html"] and body.get("data"):
                return _decode_base64url(body["data"])
            if "parts" in part:
                res = extract_email_body(part)
                if res: return res
    body = payload.get("body", {})
    if body.get("data"): return _decode_base64url(body["data"])
    return ""

def extract_event_details(text: str) -> dict:
    details = {"venue": "N/A", "date": "N/A", "time": "N/A"}
    if not text: return details
    v = VENUE_REGEX.search(text)
    d = DATE_REGEX.search(text)
    t = TIME_REGEX.search(text)
    if v: details["venue"] = v.group(1).strip()
    if d: details["date"] = d.group(1).strip()
    if t: details["time"] = t.group(1).strip()
    return details

@pubsub_fn.on_message_published(topic="gmail-club-topic")
def process_gmail_event(event: pubsub_fn.CloudEvent[pubsub_fn.MessagePublishedData]):
    """
    Triggered by Gmail Pub/Sub.
    """
    try:
        data = event.data.message.data # Base64 encoded JSON
        if not data: return
        
        payload = json.loads(base64.b64decode(data).decode('utf-8'))
        email = payload.get("emailAddress")
        history_id = payload.get("historyId")
        
        if not email or not history_id: return

        # 1. Get user credentials from Firestore
        user_ref = db.collection("users").document(email.lower())
        user_doc = user_ref.get()
        if not user_doc.exists:
            print(f"No credentials found for {email}")
            return

        user_data = user_doc.to_dict()
        creds_json = user_data.get("gmail_token")
        if not creds_json: return

        creds = google.oauth2.credentials.Credentials.from_authorized_user_info(json.loads(creds_json))
        service = build("gmail", "v1", credentials=creds)

        # 2. Get history (Simplified for Cloud Functions: just get last message)
        # In a real app, you'd use startHistoryId, but for now we'll fetch recent messages
        results = service.users().messages().list(userId='me', maxResults=5).execute()
        messages = results.get('messages', [])

        for msg_info in messages:
            msg_id = msg_info['id']
            # Check if processed
            processed_ref = db.collection("processed_messages").document(msg_id)
            if processed_ref.get().exists: continue

            # Fetch and process
            msg = service.users().messages().get(userId='me', id=msg_id).execute()
            payload = msg.get("payload", {})
            headers = payload.get("headers", [])
            sender = next((h["value"] for h in headers if h["name"] == "From"), "").lower()
            subject = next((h["value"] for h in headers if h["name"] == "Subject"), "Club Mail")

            if any(s in sender for s in OFFICIAL_CLUB_SENDERS):
                body = extract_email_body(payload)
                links = GOOGLE_FORM_REGEX.findall(body)
                if links:
                    details = extract_event_details(body)
                    # 3. Save to Firestore
                    doc_id = f"{email}_{msg_id}"
                    db.collection("club_mails").document(doc_id).set({
                        "title": subject,
                        "link": links[0],
                        "sender": sender,
                        "venue": details["venue"],
                        "date": details["date"],
                        "time": details["time"],
                        "recipient": email,
                        "timestamp": firestore.SERVER_TIMESTAMP
                    })
            
            processed_ref.set({"processed": True, "at": firestore.SERVER_TIMESTAMP})

    except Exception as e:
        print(f"Error in Cloud Function: {e}")