import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
from dotenv import load_dotenv

# Load .env file if it exists
load_dotenv()

# Path to the service account key file
SERVICE_ACCOUNT_KEY = os.path.join(os.path.dirname(__file__), "..", "serviceAccountKey.json")

def initialize_firebase():
    """Initializes Firebase Admin SDK."""
    if not firebase_admin._apps:
        # 1. Try to load from file (Local Development)
        if os.path.exists(SERVICE_ACCOUNT_KEY):
            print("Initializing Firebase from serviceAccountKey.json...")
            cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
            firebase_admin.initialize_app(cred)
        
        # 2. Try to load from Environment Variable (Cloud/Render)
        elif os.getenv("FIREBASE_SERVICE_ACCOUNT"):
            print("Initializing Firebase from environment variable...")
            try:
                service_account_info = json.loads(os.getenv("FIREBASE_SERVICE_ACCOUNT"))
                cred = credentials.Certificate(service_account_info)
                firebase_admin.initialize_app(cred)
            except Exception as e:
                print(f"❌ ERROR: Failed to parse FIREBASE_SERVICE_ACCOUNT env var: {e}")
                raise e # Fail fast so we see it in logs
        
        # 3. Critical Failure
        else:
            print("❌ ERROR: No Firebase credentials found! (Neither file nor env var)")
            raise RuntimeError("Missing Firebase Credentials. Please set FIREBASE_SERVICE_ACCOUNT in Render.")
            
    return firestore.client()

# Export a shared db instance
db = initialize_firebase()
