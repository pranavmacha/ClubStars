from fastapi import APIRouter, Request, BackgroundTasks
from fastapi.responses import RedirectResponse, JSONResponse
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
import json
import base64
import os

from .utils import (
    CLIENT_SECRETS_FILE, SCOPES, REDIRECT_URI,
    get_gmail_service, extract_email_body, extract_google_form_links
)
from .gmail_handler import process_gmail_changes, sync_historical_mails, save_history_id
from .firebase_config import db
from firebase_admin import firestore

router = APIRouter()

@router.post("/auth/google/sync")
def trigger_sync(request: Request):
    """
    Manually trigger a scan of historical emails for a specific user.
    """
    user_email = request.headers.get("user-email")
    count = sync_historical_mails(user_email)
    return JSONResponse(content={"status": "success", "synced_links": count})

@router.get("/auth/google/login")
def google_login():
    # 1. Try to load from file
    if os.path.exists(CLIENT_SECRETS_FILE):
        flow = Flow.from_client_secrets_file(
            CLIENT_SECRETS_FILE,
            scopes=SCOPES + ["https://www.googleapis.com/auth/userinfo.email", "openid"],
            redirect_uri=REDIRECT_URI,
        )
    # 2. Try to load from Environment Variable
    elif os.getenv("GOOGLE_CLIENT_SECRETS"):
        client_config = json.loads(os.getenv("GOOGLE_CLIENT_SECRETS"))
        flow = Flow.from_client_config(
            client_config,
            scopes=SCOPES + ["https://www.googleapis.com/auth/userinfo.email", "openid"],
            redirect_uri=REDIRECT_URI,
        )
    else:
        return JSONResponse(status_code=500, content={"error": "Google Client Secrets not configured"})

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

    # Determine flow source
    if os.path.exists(CLIENT_SECRETS_FILE):
        flow = Flow.from_client_secrets_file(
            CLIENT_SECRETS_FILE, 
            scopes=SCOPES + ["https://www.googleapis.com/auth/userinfo.email", "openid"], 
            redirect_uri=REDIRECT_URI
        )
    elif os.getenv("GOOGLE_CLIENT_SECRETS"):
        client_config = json.loads(os.getenv("GOOGLE_CLIENT_SECRETS"))
        flow = Flow.from_client_config(
            client_config,
            scopes=SCOPES + ["https://www.googleapis.com/auth/userinfo.email", "openid"],
            redirect_uri=REDIRECT_URI,
        )
    else:
        return JSONResponse(status_code=500, content={"error": "Google Client Secrets configuration lost during callback"})

    flow.fetch_token(code=code)
    creds = flow.credentials

    # Get user email
    from googleapiclient.discovery import build
    user_info_service = build('oauth2', 'v2', credentials=creds)
    user_info = user_info_service.userinfo().get().execute()
    email = user_info.get("email")

    if not email:
        return JSONResponse(status_code=400, content={"error": "Could not retrieve user email"})

    # Save token to Firestore for stateless Render deployment
    db.collection("users").document(email.lower()).set({
        "email": email.lower(),
        "gmail_token": json.loads(creds.to_json()),
        "last_login": firestore.SERVER_TIMESTAMP
    }, merge=True)

    return JSONResponse(content={
        "status": "Authentication successful", 
        "message": f"Token saved for {email} in Firestore",
        "email": email
    })

@router.post("/auth/google/watch")
def register_watch(request: Request):
    user_email = request.headers.get("user-email")
    service = get_gmail_service(user_email)
    if not service:
        return JSONResponse(status_code=401, content={"error": "Not authenticated"})

    # This requires the Pub/Sub topic to be set up as per the MD file
    # Replace 'clubstars' with your actual project ID
    request_body = {
        'topicName': 'projects/clubstars-b5a06/topics/gmail-club-topic',
        'labelIds': ['INBOX']
    }
    
    try:
        watch_response = service.users().watch(userId='me', body=request_body).execute()
        # Persist initial historyId to Firestore
        if user_email:
            save_history_id(user_email, watch_response.get("historyId"))
            
        return watch_response
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"error": str(e)})

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
        email = decoded_data.get("emailAddress")
        
        if history_id:
            # Trigger processing in background
            background_tasks.add_task(process_gmail_changes, history_id, email)
            
        return JSONResponse(status_code=200, content={"status": "acknowledged"})
    except Exception as e:
        print(f"Error in pubsub endpoint: {e}")
        return JSONResponse(status_code=200, content={"status": "error handled"})

@router.get("/club-mails")
def get_club_mails(request: Request):
    """
    Serve extracted links directly from Firestore.
    """
    user_email = request.headers.get("user-email")
    if not user_email:
        return JSONResponse(content=[])

    try:
        # Fetch from Firestore 'club_mails' collection
        mails_ref = db.collection("club_mails")
        query = mails_ref.where("recipient", "==", user_email.lower()) \
                         .order_by("timestamp", direction=firestore.Query.DESCENDING) \
                         .limit(50)
        
        docs = query.stream()
        data = []
        for doc in docs:
            mail_data = doc.to_dict()
            # Convert timestamp to string for JSON serialization
            if "timestamp" in mail_data and mail_data["timestamp"]:
                mail_data["timestamp"] = mail_data["timestamp"].isoformat()
            data.append(mail_data)
            
        return JSONResponse(content=data)
    except Exception as e:
        print(f"Error fetching mails from Firestore: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})
