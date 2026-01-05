As we as using the free version of Render the backend will turn down after 15mins to turn it back on we have to login to the app and press the refresh button and wait 1min then re-login to the app.
The Admin Permissions are given to Karthikeya's Collage Gmail id,The app will scan the gamils comming from asst director clubs and chapter,my gmail and karthikeya's gmail so you can guys forward the clubs related gmails from collage gmail id to any outher gmail id to check the fuctionality of the app Thank You!!

while logging in google will ask different permission you can safely accept it,pls retry 1-2 times if there is any error

# 🌟 ClubStars

**The Ultimate Campus Engagement Hub.**

ClubStars is a smart, automated platform designed to bridge the gap between student clubs and their members. By leveraging the power of **Flutter**, **FastAPI**, and **Firebase**, ClubStars automates the discovery of club events by scanning and extracting registration links directly from Gmail notifications, providing a seamless dashboard for students.

---

## 🚀 Key Features

-   **📬 Automated Event Discovery**: Uses the Gmail API to scan official club emails, extracting Google Form registration links and event details (Venue, Date, Time) automatically.
-   **🎨 Dynamic Dashboard**: A premium, "Glassmorphism" inspired UI that displays upcoming club events with beautiful banners.
-   **👑 President Portal**: Empower club leaders to manage their club's presence—update banners, logos, and matching keywords in real-time.
-   **🛡️ Admin Console**: High-level oversight for campus administrators to manage all clubs and assign presidents.
-   **🔐 Secure Authentication**: Enterprise-grade Google Sign-In with local secure token storage and background refresh capabilities.
-   **⚡ Real-time Sync**: Uses Firestore's real-time capabilities to ensure data is updated across all devices instantly.
-   **📝 Smart WebView**: Integrated registration experience with automated form handling.

---

## 🛠️ Tech Stack

### **Frontend**
-   **Framework**: [Flutter](https://flutter.dev/) (Dart)
-   **Security**: [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) for OAuth tokens.
-   **Architecture**: Service-oriented architecture with Dependency Injection ([get_it](https://pub.dev/packages/get_it)).
-   **Networking**: [Dio](https://pub.dev/packages/dio) with automated retry logic and structured logging.

### **Backend**
-   **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Python)
-   **Automation**: Google OAuth2 & Gmail API for background email processing.
-   **Deployment**: Ready for Render/Heroku with stateless background tasks.

### **Cloud & Infrastructure**
-   **Database**: Google Cloud Firestore (NoSQL).
-   **Auth**: Firebase Authentication (Google OAuth).
-   **Messaging**: Google Cloud Pub/Sub for real-time Gmail push notifications.

---

## 📁 Project Structure

```bash
ClubStars/
├── clubapp/            # Flutter Mobile Application
│   ├── lib/
│   │   ├── config/      # App settings, styles, and strings
│   │   ├── services/    # Business logic (Auth, API, Club management)
│   │   ├── screens/     # UI Layer
│   │   ├── models/      # Null-safe data models
│   │   └── utils/       # Dependency injection, Logging, Error handling
│   └── test/            # Comprehensive Unit Test suite (29+ tests)
└── backend/            # FastAPI Python Server
    ├── auth/            # OAuth flows and Gmail handlers
    ├── main.py          # Server entry point
    └── client_secret.json # Google Cloud credentials
```

---

## 🏁 Getting Started

### **Backend Setup**
1.  Navigate to `backend/`.
2.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```
3.  Set up your `.env` file (see `.env.example`).
4.  Run the server:
    ```bash
    uvicorn main:app --reload
    ```

### **Frontend Setup**
1.  Navigate to `clubapp/`.
2.  Install Flutter dependencies:
    ```bash
    flutter pub get
    ```
3.  Configure `lib/config/environment.dart` to point to your backend.
4.  Run the app:
    ```bash
    flutter run
    ```

---

## 🧪 Quality & Testing

-   **Unit Tests**: Over 29 automated tests covering models, services, and logic.
-   **Logging**: Structured logging via `AppLogger` for easy debugging.
-   **Error Handling**: Unified error management system across the entire application.

---

## 🏆 Hackathon Submission
This project was developed with a focus on **User Experience (UX)**, **Automation**, and **Scalability**. By reducing the "friction" of event discovery, ClubStars helps increase student engagement across campus.

**Developed by:** Pranav Macha & Team
