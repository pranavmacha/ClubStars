from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from auth.google_oauth import router as google_oauth_router

app = FastAPI()

# Enable CORS for Flutter app communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    """
    Simple health check endpoint to verify the server is up.
    Also used to wake up the server from cold starts.
    """
    return {"status": "ok", "message": "ClubStars Backend is awake!"}

# Include routers
app.include_router(google_oauth_router)


@app.get("/")
def root():
    return {"status": "ClubStars backend running"}
