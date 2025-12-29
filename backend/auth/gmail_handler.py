import os
import json
from firebase_admin import firestore
from .firebase_config import db
from .utils import get_gmail_service, extract_email_body, extract_google_form_links, extract_event_details, OFFICIAL_CLUB_SENDERS, extract_form_field_ids

def get_last_history_id(user_email):
    if not user_email: return None
    user_ref = db.collection("users").document(user_email.lower())
    doc = user_ref.get()
    if doc.exists:
        return doc.to_dict().get("lastHistoryId")
    return None

def save_history_id(user_email, history_id):
    if not user_email: return
    user_ref = db.collection("users").document(user_email.lower())
    user_ref.set({"lastHistoryId": history_id}, merge=True)

def is_message_processed(msg_id):
    doc_ref = db.collection("processed_messages").document(msg_id)
    return doc_ref.get().exists

def mark_message_processed(msg_id):
    doc_ref = db.collection("processed_messages").document(msg_id)
    doc_ref.set({
        "processed": True,
        "timestamp": firestore.SERVER_TIMESTAMP
    })

def process_gmail_changes(new_history_id, user_email=None):
    service = get_gmail_service(user_email)
    if not service:
        print(f"Error: No Gmail service available for {user_email}")
        return []

    last_id = get_last_history_id(user_email)
    if not last_id:
        print(f"No lastHistoryId found for {user_email}, skipping history list")
        if user_email:
            save_history_id(user_email, new_history_id)
        return []

    try:
        history_results = service.users().history().list(
            userId='me',
            startHistoryId=last_id,
            historyTypes=['messageAdded']
        ).execute()

        extracted_links = []
        histories = history_results.get('history', [])
        
        for h in histories:
            messages_added = h.get('messagesAdded', [])
            for msg_item in messages_added:
                msg = msg_item.get('message', {})
                msg_id = msg.get('id')
                
                if msg_id and not is_message_processed(msg_id):
                    links = process_single_message(service, msg_id, user_email)
                    if links:
                        extracted_links.extend(links)
                    mark_message_processed(msg_id)

        if user_email:
            save_history_id(user_email, new_history_id)
        return extracted_links

    except Exception as e:
        print(f"Error processing history for {user_email}: {e}")
        return []

def process_single_message(service, msg_id, user_email):
    try:
        msg_data = service.users().messages().get(
            userId="me",
            id=msg_id,
            format="full"
        ).execute()

        payload = msg_data.get("payload", {})
        headers = payload.get("headers", [])
        
        sender = next((h["value"] for h in headers if h["name"] == "From"), "").lower()
        subject = next((h["value"] for h in headers if h["name"] == "Subject"), "Club Mail")
        
        # Filter by sender
        is_official = any(email in sender for email in OFFICIAL_CLUB_SENDERS)
        if not is_official:
            return []

        body_text = extract_email_body(payload)
        links = extract_google_form_links(body_text)
        details = extract_event_details(body_text)
        
        if links:
            print(f"Extracted {len(links)} links from message {msg_id}")
            # Map each link to its field IDs
            link_data = []
            for link in links:
                field_mappings = extract_form_field_ids(link)
                link_data.append({
                    "url": link,
                    "field_mappings": field_mappings
                })
            
            save_extracted_links(link_data, msg_id, sender, subject, details, user_email)
            
        return links

    except Exception as e:
        print(f"Error processing message {msg_id}: {e}")
        return []

def sync_historical_mails(user_email=None):
    """
    Search for past emails from official senders and process them.
    """
    service = get_gmail_service(user_email)
    if not service:
        print(f"Error: No Gmail service available for sync ({user_email})")
        return 0

    total_synced = 0
    for official_sender in OFFICIAL_CLUB_SENDERS:
        query = f"from:{official_sender}"
        try:
            results = service.users().messages().list(userId='me', q=query, maxResults=10).execute()
            messages = results.get('messages', [])
            
            for msg_info in messages:
                msg_id = msg_info['id']
                if not is_message_processed(msg_id):
                    links = process_single_message(service, msg_id, user_email)
                    if links:
                        total_synced += len(links)
                    mark_message_processed(msg_id)
        except Exception as e:
            print(f"Error syncing mails for {official_sender}: {e}")
            
    return total_synced

def save_extracted_links(link_data, msg_id, sender, subject, details, user_email):
    for item in link_data:
        link = item["url"]
        field_mappings = item["field_mappings"]
        
        # Create a unique doc ID to prevent duplicates in Firestore
        doc_id = f"{user_email.lower()}_{msg_id}_{link[:50]}"
        # Sanitize for firestore document id (remove problematic chars)
        doc_id = "".join(c for c in doc_id if c.isalnum() or c in "_-")
        
        doc_ref = db.collection("club_mails").document(doc_id)
        doc_ref.set({
            "link": link,
            "field_mappings": field_mappings,
            "msg_id": msg_id,
            "sender": sender,
            "title": subject,
            "venue": details.get("venue", "N/A"),
            "date": details.get("date", "N/A"),
            "time": details.get("time", "N/A"),
            "recipient": user_email.lower() if user_email else "unknown",
            "timestamp": firestore.SERVER_TIMESTAMP
        }, merge=True)
