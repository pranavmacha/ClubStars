import firebase_admin
from firebase_admin import credentials, firestore
import os

# Path to the service account key file
# The user will provide this as serviceAccountKey.json
SERVICE_ACCOUNT_KEY = os.path.join(os.path.dirname(__file__), "..", "serviceAccountKey.json")

def initialize_firebase():
    """Initializes Firebase Admin SDK."""
    if not firebase_admin._apps:
        if os.path.exists(SERVICE_ACCOUNT_KEY):
            cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
            firebase_admin.initialize_app(cred)
        else:
            # Fallback for environments where the key might be in env vars 
            # or using default credentials
            firebase_admin.initialize_app()
    return firestore.client()

# Export a shared db instance
db = initialize_firebase()
