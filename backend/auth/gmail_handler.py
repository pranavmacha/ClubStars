import os
import json
from .utils import get_gmail_service, extract_email_body, extract_google_form_links, extract_event_details, HISTORY_FILE, OFFICIAL_CLUB_SENDERS

PROCESSED_MSGS_FILE = "processed_messages.json"

def get_last_history_id():
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, "r") as f:
            return json.load(f).get("lastHistoryId")
    return None

def save_history_id(history_id):
    with open(HISTORY_FILE, "w") as f:
        json.dump({"lastHistoryId": history_id}, f)

def is_message_processed(msg_id):
    if not os.path.exists(PROCESSED_MSGS_FILE):
        return False
    with open(PROCESSED_MSGS_FILE, "r") as f:
        try:
            processed = json.load(f)
            return msg_id in processed
        except:
            return False

def mark_message_processed(msg_id):
    processed = []
    if os.path.exists(PROCESSED_MSGS_FILE):
        with open(PROCESSED_MSGS_FILE, "r") as f:
            try:
                processed = json.load(f)
            except:
                pass
    processed.append(msg_id)
    # Keep only last 1000 to avoid file bloat
    processed = processed[-1000:]
    with open(PROCESSED_MSGS_FILE, "w") as f:
        json.dump(processed, f)

def process_gmail_changes(new_history_id):
    service = get_gmail_service()
    if not service:
        print("Error: No Gmail service available")
        return []

    last_id = get_last_history_id()
    if not last_id:
        print("No lastHistoryId found, skipping history list")
        save_history_id(new_history_id)
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
                    links = process_single_message(service, msg_id)
                    if links:
                        extracted_links.extend(links)
                    mark_message_processed(msg_id)

        save_history_id(new_history_id)
        return extracted_links

    except Exception as e:
        print(f"Error processing history: {e}")
        return []

def process_single_message(service, msg_id):
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
            save_extracted_links(links, msg_id, sender, subject, details)
            
        return links

    except Exception as e:
        print(f"Error processing message {msg_id}: {e}")
        return []

def sync_historical_mails():
    """
    Search for past emails from official senders and process them.
    """
    service = get_gmail_service()
    if not service:
        print("Error: No Gmail service available for sync")
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
                    links = process_single_message(service, msg_id)
                    if links:
                        total_synced += len(links)
                    mark_message_processed(msg_id)
        except Exception as e:
            print(f"Error syncing mails for {official_sender}: {e}")
            
    return total_synced

def save_extracted_links(links, msg_id, sender, subject, details):
    links_file = "extracted_links.json"
    data = []
    if os.path.exists(links_file):
        with open(links_file, "r") as f:
            try:
                data = json.load(f)
            except:
                pass
    
    # Check for existing links to avoid duplicates in the file
    existing_links = {item['link'] for item in data}
    
    for link in links:
        if link not in existing_links:
            data.append({
                "link": link,
                "msg_id": msg_id,
                "sender": sender,
                "title": subject,
                "venue": details.get("venue", "N/A"),
                "date": details.get("date", "N/A"),
                "time": details.get("time", "N/A")
            })
    
    with open(links_file, "w") as f:
        json.dump(data, f, indent=2)
