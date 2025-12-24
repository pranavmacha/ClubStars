from fastapi import APIRouter, Request, BackgroundTasks
from fastapi.responses import RedirectResponse, JSONResponse
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
import json
import base64
import os

from .utils import (
    CLIENT_SECRETS_FILE, SCOPES, REDIRECT_URI, TOKEN_FILE, HISTORY_FILE,
    get_gmail_service, extract_email_body, extract_google_form_links
)
from .gmail_handler import process_gmail_changes, sync_historical_mails

router = APIRouter()

@router.post("/auth/google/sync")
def trigger_sync():
    """
    Manually trigger a scan of historical emails.
    """
    count = sync_historical_mails()
    return JSONResponse(content={"status": "success", "synced_links": count})



@router.get("/auth/google/login")
def google_login():
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRETS_FILE,
        scopes=SCOPES,
        redirect_uri=REDIRECT_URI,
    )

    authorization_url, _ = flow.authorization_url(
        access_type="offline",
        include_granted_scopes="true",
        prompt="consent",
    )

    return RedirectResponse(authorization_url)


@router.get("/auth/google/callback")
def google_callback(request: Request):
    code = request.query_params.get("code")
    if not code:
        return JSONResponse(status_code=400, content={"error": "Authorization code not found"})

    flow = Flow.from_client_secrets_file(CLIENT_SECRETS_FILE, scopes=SCOPES, redirect_uri=REDIRECT_URI)
    flow.fetch_token(code=code)
    creds = flow.credentials

    with open(TOKEN_FILE, "w") as token:
        token.write(creds.to_json())

    return JSONResponse(content={"status": "Authentication successful", "message": "Token saved."})


@router.post("/auth/google/watch")
def register_watch():
    service = get_gmail_service()
    if not service:
        return JSONResponse(status_code=401, content={"error": "Not authenticated"})

    # This requires the Pub/Sub topic to be set up as per the MD file
    request_body = {
        'topicName': 'projects/clubstars/topics/gmail-club-topic',
        'labelIds': ['INBOX']
    }
    
    try:
        watch_response = service.users().watch(userId='me', body=request_body).execute()
        # Persist initial historyId
        with open(HISTORY_FILE, "w") as f:
            json.dump({"lastHistoryId": watch_response.get("historyId")}, f)
            
        return watch_response
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"DEBUG: Watch Error type: {type(e)}")
        print(f"DEBUG: Watch Error repr: {repr(e)}")
        return JSONResponse(status_code=500, content={"error": str(e), "repr": repr(e)})

@router.post("/pubsub/gmail")
async def pubsub_gmail_push(request: Request, background_tasks: BackgroundTasks):
    """
    Handle Pub/Sub push notifications from Gmail.
    """
    try:
        body = await request.json()
        message = body.get("message", {})
        data_b64 = message.get("data")
        
        if not data_b64:
            return JSONResponse(status_code=200, content={"status": "no data"})

        # Decode data
        decoded_data = json.loads(base64.b64decode(data_b64).decode("utf-8"))
        history_id = decoded_data.get("historyId")
        
        if history_id:
            # Trigger heavy processing in background
            background_tasks.add_task(process_gmail_changes, history_id)
            
        return JSONResponse(status_code=200, content={"status": "acknowledged"})
    except Exception as e:
        print(f"Error in pubsub endpoint: {e}")
        # Always return 200 to avoid Pub/Sub retries if it's a parsing error
        return JSONResponse(status_code=200, content={"status": "error handled"})

@router.get("/club-mails")
def get_club_mails():
    """
    Serve extracted links to the Flutter app.
    """
    links_file = "extracted_links.json"
    data = []
    if os.path.exists(links_file):
        with open(links_file, "r") as f:
            try:
                data = json.load(f)
            except:
                pass
    
    # Reverse to show newest first
    return JSONResponse(content=data[::-1])
