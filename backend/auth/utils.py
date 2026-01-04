import os
import json
import base64
import re
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow
from google.auth.transport.requests import Request as GoogleRequest
from googleapiclient.discovery import build

# Constants
OFFICIAL_CLUB_SENDERS = {
    "asstdir.cac@vitap.ac.in",
    "codered@vitap.ac.in",
    # Test senders (Add your forwarding email here)
    "dheeraj.24bce7156@vitapstudent.ac.in",
    "pranav.24bce7150@vitapstudent.in"
}
TOKEN_FILE = "token.json"
HISTORY_FILE = "history.json"
CLIENT_SECRETS_FILE = "client_secret.json"
TOKENS_DIR = "tokens"

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
    "openid"
]

REDIRECT_URI = "http://localhost:8000/auth/google/callback"

# Helpers
def get_client_config():
    """ Load Google client configuration from file or environment. """
    if os.path.exists(CLIENT_SECRETS_FILE):
        with open(CLIENT_SECRETS_FILE, 'r') as f:
            return json.load(f)
    elif os.getenv("GOOGLE_CLIENT_SECRETS"):
        return json.loads(os.getenv("GOOGLE_CLIENT_SECRETS"))
    return None
def extract_sender_email(sender: str) -> str:
    """
    Extract email from: Name <email@domain>
    """
    if "<" in sender and ">" in sender:
        return sender.split("<")[1].split(">")[0].lower()
    return sender.lower()

def _decode_base64url(data: str) -> str:
    if not data:
        return ""
    decoded_bytes = base64.urlsafe_b64decode(data + "===")
    return decoded_bytes.decode("utf-8", errors="ignore")


def extract_email_body(payload: dict) -> str:
    """
    Recursively extract email body.
    Prefer text/plain, fallback to text/html.
    """
    if "parts" in payload:
        for part in payload["parts"]:
            mime_type = part.get("mimeType", "")
            body = part.get("body", {})

            if mime_type == "text/plain" and body.get("data"):
                return _decode_base64url(body["data"])

            if mime_type == "text/html" and body.get("data"):
                return _decode_base64url(body["data"])

            if "parts" in part:
                text = extract_email_body(part)
                if text:
                    return text

    body = payload.get("body", {})
    if body.get("data"):
        return _decode_base64url(body["data"])

    return ""

GOOGLE_FORM_REGEX = re.compile(
    r"(https://docs\.google\.com/forms/[^\s<>]+|https://forms\.gle/[^\s<>]+)"
)

VENUE_REGEX = re.compile(r"(?i)venue\s*[:\-]\s*([^\n\r]+)")
DATE_REGEX = re.compile(r"(?i)date\s*[:\-]\s*([^\n\r]+)")
TIME_REGEX = re.compile(r"(?i)time\s*[:\-]\s*([^\n\r]+)")

def extract_google_form_links(text: str) -> list[str]:
    if not text:
        return []
    return GOOGLE_FORM_REGEX.findall(text)

def extract_event_details(text: str) -> dict:
    """
    Extract Venue, Date, and Time from the email body.
    """
    details = {
        "venue": "N/A",
        "date": "N/A",
        "time": "N/A"
    }
    if not text:
        return details
        
    venue_match = VENUE_REGEX.search(text)
    date_match = DATE_REGEX.search(text)
    time_match = TIME_REGEX.search(text)
    
    if venue_match:
        details["venue"] = venue_match.group(1).strip()
    if date_match:
        details["date"] = date_match.group(1).strip()
    if time_match:
        details["time"] = time_match.group(1).strip()
        
    return details

def get_gmail_service(user_email=None):
    if not user_email:
        # Fallback to legacy token.json if no user_email provided
        if not os.path.exists(TOKEN_FILE):
            return None
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    else:
        # Load from Firestore for Render/Cloud
        from .firebase_config import db
        user_ref = db.collection("users").document(user_email.lower())
        doc = user_ref.get()
        if not doc.exists:
            print(f"No credentials found in Firestore for {user_email}")
            return None
        
        user_data = doc.to_dict()
        token_data = user_data.get("gmail_token")
        if not token_data:
            return None
            
        try:
            # token_data could be a JSON string (from Flutter) or a dict
            if isinstance(token_data, str):
                info = json.loads(token_data)
            else:
                info = token_data
            
            # Check if we have the full 'Authorized User' format
            if all(k in info for k in ["client_id", "client_secret", "refresh_token"]):
                creds = Credentials.from_authorized_user_info(info, SCOPES)
            elif "server_auth_code" in info and not info.get("refresh_token"):
                # CRITICAL FIX: Exchange the code for a full token with refresh
                client_config = get_client_config()
                if client_config:
                    print(f"DEBUG: Exchanging code for {user_email}...")
                    try:
                        # For mobile server_auth_code exchange, redirect_uri usually needs to be None
                        flow = Flow.from_client_config(
                            client_config,
                            scopes=SCOPES,
                            redirect_uri=None
                        )
                        flow.fetch_token(code=info["server_auth_code"])
                        creds = flow.credentials
                        
                        # Save the FULL credentials back to Firestore immediately
                        db.collection("users").document(user_email.lower()).set({
                            "gmail_token": json.loads(creds.to_json())
                        }, merge=True)
                        print(f"Successfully exchanged and saved tokens for {user_email}")
                    except Exception as exchange_error:
                        print(f"Error during code exchange for {user_email}: {exchange_error}")
                        if "invalid_grant" in str(exchange_error).lower():
                            print(f"Clearing stale server_auth_code for {user_email}")
                            db.collection("users").document(user_email.lower()).update({
                                "gmail_token.server_auth_code": firestore.DELETE
                            })
                        return None
                else:
                    print(f"No client config found to exchange code for {user_email}")
                    return None
            else:
                # Fallback path - needs client_id/secret for refresh
                client_config = get_client_config()
                client_id = None
                client_secret = None
                if client_config:
                    web_config = client_config.get("web") or client_config.get("installed")
                    if web_config:
                        client_id = web_config.get("client_id")
                        client_secret = web_config.get("client_secret")

                creds = Credentials(
                    token=info.get("access_token") or info.get("token"),
                    refresh_token=info.get("refresh_token"),
                    token_uri="https://oauth2.googleapis.com/token",
                    client_id=client_id,
                    client_secret=client_secret,
                    scopes=SCOPES
                )
        except Exception as e:
            print(f"Error parsing token for {user_email}: {e}")
            return None

    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(GoogleRequest())
            # Save refreshed token back
            if user_email:
                from .firebase_config import db
                db.collection("users").document(user_email.lower()).set({
                    "gmail_token": json.loads(creds.to_json())
                }, merge=True)
            else:
                with open(TOKEN_FILE, "w") as token:
                    token.write(creds.to_json())
        except Exception as e:
            print(f"Error refreshing token for {user_email}: {e}")
            return None
            
    return build("gmail", "v1", credentials=creds)

# --- Google Form Field Extraction (DELETED: Moved to in-app WebView JS injection) ---
