from auth.firebase_config import db
import datetime

def test_connection():
    try:
        print("Checking Firestore connection...")
        doc_ref = db.collection("test_connection").document("status")
        doc_ref.set({
            "status": "connected",
            "last_checked": datetime.datetime.now()
        })
        print("Success! Data written to Firestore.")
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    test_connection()
