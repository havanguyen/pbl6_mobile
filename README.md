# 🏥 Medicalink App - The Ultimate Healthcare Ecosystem (PBL6 Mobile)

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/havanguyen/pbl6_mobile)

```text
███╗   ███╗███████╗██████╗ ██╗ ██████╗ █████╗ ██╗     ██╗███╗   ██╗██╗  ██╗
████╗ ████║██╔════╝██╔══██╗██║██╔════╝██╔══██╗██║     ██║████╗  ██║██║ ██╔╝
██╔████╔██║█████╗  ██║  ██║██║██║     ███████║██║     ██║██╔██╗ ██║█████╔╝ 
██║╚██╔╝██║██╔══╝  ██║  ██║██║██║     ██╔══██║██║     ██║██║╚██╗██║██╔═██╗ 
██║ ╚═╝ ██║███████╗██████╔╝██║╚██████╗██║  ██║███████╗██║██║ ╚████║██║  ██╗
╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
```

> **"Bridging the gap between Patients and Doctors with cutting-edge technology."**

---

## 🔖 1. Project Manifesto

### 1.1 The Vision
In a rapidly developing nation like Vietnam, healthcare accessibility remains a critical challenge. Urban hospitals are overcrowded, rural areas lack specialists, and the booking process is often manual, opaque, and inefficient. **Medicalink App** was born from a vision to **digitalize the entire patient journey**. We envision a future where:
*   A mother in a rural province can book a consultation with a top pediatrician in Ho Chi Minh City without traveling for hours just to get a queue number.
*   A busy office worker can schedule a check-up in 30 seconds during their lunch break.
*   Doctors can focus 100% on treating patients, leaving the scheduling and administrative burden to our intelligent system.

### 1.2 Core Values
1.  **Transparency:** No hidden fees, no fake reviews. extensive doctor profiles with verified credentials.
2.  **Privacy:** Patient data is sacred. We use industry-standard encryption (AES-256) and strictly adhere to medical data privacy principles.
3.  **Reliability:** The system must work 24/7. Health emergencies do not wait for "server maintenance".
4.  **Empathy:** Technology should feel human. Our UI/UX is designed to be calming, accessible, and inclusive for all ages.

---

## 📑 2. Table of Contents

1.  **[Project Manifesto](#-1-project-manifesto)**
2.  **[User Manual (For Patients)](#-3-user-manual)**
3.  **[Provider Manual (For Doctors)](#-4-provider-manual)**
4.  **[Admin Manual (For Staff)](#-5-admin-manual)**
5.  **[Developer Handbook](#-6-developer-handbook)**
    *   [Architecture](#61-architecture-overview)
    *   [Folder Structure](#62-folder-structure-deep-dive)
    *   [State Management](#63-state-management)
    *   [Networking](#64-networking-layer)
6.  **[Design System & UI](#-7-design-system--ui)**
7.  **[API Reference (The Core)](#-8-api-reference)**
    *   [Auth & Identity](#81-auth--identity-endpoints)
    *   [Appointments](#82-appointment-endpoints)
    *   [Doctors & Profiles](#83-doctor-endpoints)
    *   [Blogs & Content](#84-blog-endpoints)
    *   [Reviews & Feedback](#85-review-endpoints)
8.  **[Data Dictionary](#-9-data-dictionary)**
    *   [Core Entities](#91-core-entities)
    *   [Content Entities](#92-content-entities)
    *   [System Entities](#93-system-entities)
9.  **[Navigation Graph](#-10-navigation-graph)**
10. **[Deployment Bible](#-11-deployment-bible)**
11. **[Troubleshooting](#-12-troubleshooting)**
12. **[License](#-13-license)**

---

## 📘 3. User Manual

This section is for the end-users (patients).

### 3.1 Getting Started
1.  **Download the App:** Available on iOS (App Store) and Android (Google Play).
2.  **Sign Up:**
    *   Open the app.
    *   Click "Register" at the bottom of the Login screen.
    *   Enter your **Full Name**, **Email** (must be valid format), and **Password** (min 8 chars).
    *   *Tip:* Use a real email as we send booking confirmations there!
3.  **Complete Profile:**
    *   Go to "Settings" -> "Profile".
    *   Update your **Date of Birth** and **Gender**. This helps doctors diagnose you better.

### 3.2 Booking an Appointment
The core feature of Medicalink.
1.  **Search:** Use the search bar on the Home tab. Type "Dentist" or a doctor's name.
2.  **Filter:** Click the filter icon. Select "Rating: 4.5+" to see top doctors.
3.  **Select Slot:**
    *   Click on a Doctor's card.
    *   Scroll down to the Calendar.
    *   Select a **Date**.
    *   Select a **Time** (e.g., 09:30 AM). Green slots are available.
4.  **Confirm:**
    *   Review the details (Price, Location).
    *   Input a "Reason for Visit" (e.g., "I have a headache").
    *   Press "Confirm".
5.  **Success:** You will see a success screen and receive an email.

### 3.3 Managing Appointments
1.  **View List:** Go to the "Appointments" tab.
2.  **Cancel:**
    *   Find an "Upcoming" appointment.
    *   Click "Cancel".
    *   **Note:** You must provide a reason. Excessive cancellations may lock your account.
3.  **Reschedule:**
    *   Click "Reschedule".
    *   Pick a new date/time.
    *   Wait for Doctor approval (if configured).

### 3.4 Q&A Community
1.  **Ask:** Click the "Community" tab -> "Ask Question".
2.  **Browse:** Read answers from verified doctors on topics like "Nutrition", "Mental Health".

---

## 👨‍⚕️ 4. Provider Manual

This section is for Doctors.

### 4.1 Profile Optimization
Your profile is your storefront.
*   **Avatar:** Upload a professional headshot.
*   **Bio:** Write a detailed description of your expertise. Use HTML formatting if supported.
*   **Specialty:** Ensure your primary specialty is correct (e.g., Cardiology).
*   **Price:** Set your standard consultation fee.

### 4.2 Schedule Management (Office Hours)
Medicalink gives you total control over your time.
*   **Default Schedule:** Set your typical week (e.g., Mon-Fri, 9-5).
*   **Exceptions:** Going on vacation? Add a time-off block in "Calendar Settings".
*   **Slot Duration:** Choose between 15, 30, 45, or 60 minute slots.

### 4.3 Accepting Appointments
*   **Auto-Accept:** (Default) Requests are automatically confirmed if the slot is free.
*   **Manual-Accept:** Toggle this in settings if you want to screen requests.

---

## 🛡 5. Admin Manual

For Super Admins and Staff.

### 5.1 User Moderation
*   **Ban User:** Navigate to `UserPermissionDetailPage`. Toggle "Banned".
*   **Verify Doctor:** Check their uploaded documents. If valid, click "Approve".

### 5.2 Content Moderation
*   **Blog Posts:** Review pending posts. Check for medical accuracy. Publish or Reject.
*   **Q&A:** Remove spam or offensive questions.

### 5.3 Master Data
*   **Specialties:** Add new medical fields (e.g., "Neurology") in `ListSpecialtyPage`.
*   **Locations:** Manage hospital/clinic addresses in `ListLocationWorkPage`.

---

## 🛠 6. Developer Handbook

### 6.1 Architecture Overview
Medicalink is built with a **Layered Architecture** enforcing Separation of Concerns.

#### The Layers
1.  **Presentation (View):**
    *   **Responsibility:** Rendering UI, capturing user input.
    *   **Components:** Flutter Widgets (`StatelessWidget`, `StatefulWidget`).
    *   **Rule:** NO BUSINESS LOGIC HERE.
2.  **Logic (ViewModel):**
    *   **Responsibility:** Holding state, validating input, calling Use Cases.
    *   **Components:** `ChangeNotifier` (Provider) or `Cubit` (Bloc).
    *   **Rule:** NO UI CODE HERE (No `BuildContext`).
3.  **Domain (Entity):**
    *   **Responsibility:** Pure Dart objects representing data.
    *   **Components:** `Freezed` classes (`.freezed.dart`, `.g.dart`).
    *   **Rule:** PURE DART. No Flutter dependencies.
4.  **Data (Service/Repository):**
    *   **Responsibility:** Fetching data from Remote (API) or Local (DB).
    *   **Components:** `Dio` clients, `SharedPreferences`.

### 6.2 Folder Structure Deep Dive
Every file has a home.

```bash
lib/
├── main.dart                  # [Entry] App bootstrapper. Sets up Providers, Themes, Crashlytics.
├── firebase_options.dart      # [Config] Auto-generated Firebase settings.
│
├── model/                     # [Layer 3 & 4] Data & Domain
│   ├── entities/              # The "Truth". Immutable data classes.
│   │   ├── users/             # Patient, Doctor, Staff models.
│   │   ├── appointment/       # AppointmentData, DoctorSlot.
│   │   └── ...
│   ├── dto/                   # Data Transfer Objects.
│   │   ├── auth_dto.dart      # LoginRequest, RegisterResponse.
│   │   └── ...
│   └── services/              # The "Workers".
│       ├── remote/            # HTTP Clients (Dio).
│       │   ├── auth_service.dart
│       │   ├── doctor_service.dart
│       │   ├── blog_service.dart
│       │   └── ...
│       └── local/             # Cache/Storage.
│           ├── store.dart     # SecureStorage wrapper.
│           └── ...
│
├── view_model/                # [Layer 2] Business Logic
│   ├── auth/                  # LoginVm, RegisterVm.
│   ├── appointment/           # AppointmentVm (Booking flow state).
│   └── ...
│
├── view/                      # [Layer 1] UI Screens
│   ├── auth/                  # LoginPage, RegisterPage.
│   ├── home/                  # Dashboard tabs.
│   ├── appointment/           # Booking wizard steps.
│   └── ...
│
└── shared/                    # [Common] Utilities
    ├── constants/             # AppColors, ApiEndpoints.
    ├── themes/                # LightTheme, DarkTheme.
    ├── routes/                # Route names & Generator.
    ├── utils/                 # Validations, Formatters.
    └── widgets/               # Reusable atomic widgets (Buttons, Inputs).
```

### 6.3 State Management
We use a **Hybrid Approach**: `Provider` + `Bloc`.

#### Why Hybrid?
*   **Bloc** is excellent for **Global, Event-Driven State** (Theme, Language, Auth Status). It ensures strict state transitions.
*   **Provider** is superior for **Ephemeral, Screen-Scoped State** (Form inputs, loading lists). It requires less boilerplate than Bloc.

#### ViewModel Lifecycle (Example: `AppointmentVm`)
1.  **Initialization:** Created via `MultiProvider` in `main.dart` or scoped to a route.
2.  **Loading Data:**
    *   Method: `fetchAppointments(fromDate, toDate)`
    *   Action: Checks `_isLoading`. Sets to `true`. Notifies listeners.
    *   Strategy: **Cache First** (Load local DB) -> **Sync** (Fetch API in background) -> **Update** (Save to DB, refresh UI).
3.  **User Interaction:**
    *   Method: `cancelAppointment(id)`
    *   Action: Sets `_actionLoading[id] = true` (Granular loading state).
    *   Result: On success, calls `refresh()` to update the list.

### 6.4 Networking Layer
We use **Dio** for all HTTP requests.

#### The Secure Client
Located in `AuthService.getSecureDioInstance()`.
*   **AuthInterceptor:** Automatically attaches `Bearer <token>` to every request.
*   **Token Refresh Logic:**
    1.  Request fails with `401 Unauthorized`.
    2.  Interceptor pauses the request queue.
    3.  Calls `/auth/refresh` using the Refresh Token.
    4.  If success: Retries the original request with new token.
    5.  If fail: Forces Logout (clears secure storage).

---

## 🎨 7. Design System & UI

Medicalink adheres to a strict design system defined in `lib/shared/themes/`.

### 7.1 Color Palette (`AppColors`)

#### Brand Colors
*   **Primary Blue:** `#1e9df1` (Light) / `#64B5F6` (Dark) - Used for buttons, active tabs, and highlights.
*   **Accent:** `#E3ECF6` (Light) - Used for secondary button backgrounds and hover states.

#### Semantic Colors
*   **Success:** `#2dd356` (Light) / `#81C784` (Dark) - Completed appointments, verified status.
*   **Error:** `#f7463d` (Light) / `#E57373` (Dark) - Cancellations, form errors.
*   **Warning:** `#ffa00d` (Light) / `#FFB74D` (Dark) - Pending actions.

#### Neutrals
*   **Surface:** `#FFFFFF` (Light) / `#1E1E1E` (Dark) - Cards, dialogs.
*   **Background:** `#FFFFFF` (Light) / `#121212` (Dark) - Main scaffold background.

### 7.2 Typography
We use **Google Fonts** (inter/poppins) configured in `AppTheme`.
*   **Headlines:** Bold, High Emphasis.
*   **Body:** Regular, legible size (14sp/16sp).
*   **Captions:** Grey, smaller size (12sp).

---

## 🔌 8. API Reference

This is a comprehensive documentation of the Backend APIs consumed by the Mobile App.
*Base URL:* `https://api.medicalink.vn/api/v1` (Configured in `.env`)

### 8.1 Auth & Identity Endpoints

#### Login
*   **POST** `/auth/login`
*   **Body:**
    ```json
    {
      "email": "user@example.com",
      "password": "secretpassword"
    }
    ```
*   **Response (200):**
    ```json
    {
      "data": {
        "access_token": "ey...",
        "refresh_token": "ey...",
        "user": { "role": "PATIENT", "id": "..." }
      }
    }
    ```

#### Register
*   **POST** `/auth/register`
*   **Body:**
    ```json
    {
      "fullName": "John Doe",
      "email": "john@example.com",
      "password": "password123"
    }
    ```
*   **Response (201):**
    ```json
    {
      "success": true,
      "message": "User registered successfully"
    }
    ```

#### Refresh Token
*   **POST** `/auth/refresh`
*   **Body:** `{ "refresh_token": "..." }`
*   **Description:** Used automatically by Dio Interceptor.

### 8.2 Appointment Endpoints

#### Get My Appointments
*   **GET** `/appointments/me`
*   **Query Params:**
    *   `status`: (Optional) `PENDING` | `CONFIRMED`
    *   `fromDate`: `YYYY-MM-DD`
    *   `toDate`: `YYYY-MM-DD`
*   **Response (200):** list of `AppointmentData` objects.

#### Create Appointment
*   **POST** `/appointments`
*   **Body:**
    ```json
    {
      "doctorId": "uuid",
      "serviceDate": "2025-10-25",
      "timeStart": "09:30",
      "reason": "Headache"
    }
    ```

#### Cancel Appointment
*   **DELETE** `/appointments/{id}`
*   **Body:** `{ "reason": "Conflict" }`

### 8.3 Doctor Endpoints

#### Search Doctors
*   **GET** `/doctors`
*   **Query Params:**
    *   `search`: String
    *   `specialtyId`: UUID
    *   `minRating`: Double
*   **Response:** Paginated list of `Doctor`.

#### Get Doctor Slots
*   **GET** `/doctors/profile/{id}/slots`
*   **Query Params:** `date=2025-10-25`
*   **Response:**
    ```json
    [
      { "time": "09:00", "isAvailable": true },
      { "time": "09:30", "isAvailable": false }
    ]
    ```

#### Get Doctor Public Profile
*   **GET** `/doctors/profile/public`
*   **Query Params:** `specialtyIds`, `workLocationIds`
*   **Response:** List of public doctor profiles capable of being viewed by guests.

### 8.4 Blog Endpoints

#### Get Blogs
*   **GET** `/blogs`
*   **Query Params:**
    *   `categoryId`: Filter by topic.
    *   `search`: Keyword search.
    *   `sortOrder`: `DESC` (Newest first).
*   **Response:** Paginated list of `Blog`.

#### Get Blog Categories
*   **GET** `/blogs/categories`
*   **Response:** List of topic categories (e.g., "Nutrition", "Cardiology").

### 8.5 Review Endpoints

#### Get Reviews
*   **GET** `/reviews/doctor/{id}`
*   **Query Params:** `page=1`, `limit=5`.
*   **Response:** List of `Review` objects.

#### Delete Review
*   **DELETE** `/reviews/{id}`
*   **Description:** Admin only.

---

## 🗄 9. Data Dictionary

Medicalink uses a strict type system. Here are the core entities.

### 9.1 Core Entities

#### Public Users (`User`)
The base for all actors.
*   `access_token` (String, JWT)
*   `role` (Enum: `ADMIN`, `DOCTOR`, `PATIENT`)

#### Doctor (`Doctor`)
Represents a medical professional.
*   `id` (UUID): Primary Key.
*   `fullName` (String): Display name (e.g., "Dr. House").
*   `email` (String): Contact email.
*   `role` (String): Always "doctor".
*   `bio` (HTML): Rich text biography.
*   `specialtyId` (UUID): Foreign Key to `Specialty`.
*   `appointmentDuration` (Int): Default slot size in minutes (e.g., 30).
*   `workLocationIds` (List<UUID>): Clinics where they work.
*   `rating` (Double): Computed average (0-5).
*   `price` (Double): Base consultation fee.

#### Patient (`Patient`)
Represents an end-user.
*   `id` (UUID): Primary Key.
*   `fullName` (String): Official name.
*   `dateOfBirth` (DateTime): For age calculation.
*   `addressLine` (String): Home address.
*   `district` (String): For location-based services.
*   `province` (String): For location-based services.

#### Appointment (`AppointmentData`)
The link between Patient and Doctor.
*   `id` (UUID)
*   `patientId` (UUID)
*   `doctorId` (UUID)
*   `status` (Enum): `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`, `NO_SHOW`.
*   `timeSlot` (DateTime)
*   `reason` (String): User provided symptom.
*   `priceAmount` (Double): Cost of visit.
*   `currency` (String): "VND" or "USD".

### 9.2 Content Entities

#### Blog (`Blog`)
*   `id` (UUID)
*   `title` (String): Article headline.
*   `slug` (String): URL friendly name.
*   `content` (HTML): Main body.
*   `thumbnailUrl` (String): Cover image.
*   `authorName` (String): Credited doctor.
*   `category` (`BlogCategory`): Nested object.

#### Review (`Review`)
*   `id` (UUID)
*   `rating` (Int): 1-5 Stars.
*   `title` (String): Summary.
*   `body` (String): Detailed feedback.
*   `authorName` (String): Public name of reviewer.
*   `doctorId` (UUID): Target of review.

#### Specialty (`Specialty`)
*   `id` (UUID)
*   `name` (String): e.g., "Cardiology".
*   `description` (String): Explanation of field.
*   `iconUrl` (String): Visual asset.

### 9.3 System Entities

#### WorkLocation (`WorkLocation`)
*   `id` (UUID)
*   `name` (String): e.g., "City International Hospital".
*   `address` (String): Physical location.

---

## 🗺 10. Navigation Graph

Documenting the `Routes` class (`lib/shared/routes/routes.dart`).

| Route Name | Constant | Screen | Description |
| :--- | :--- | :--- | :--- |
| Login | `/login` | `LoginPage` | Initial entry point. |
| Doctor Home | `/mainPageDoctor` | `MainPageDoctor` | Dashboard for doctors. |
| Admin Home | `/mainPageAdmin` | `MainPageAdmin` | Dashboard for staff. |
| Patient Home | `/` (Implicit) | `MainPage` | Default home for patients. |
| Appointment List | `/listAppointment` | `ListAppointmentPage` | User's booking history. |
| Doctor Detail | `/doctorDetail` | `DoctorDetailPage` | Public profile of a doctor. |
| Booking Flow | `/createAppointment` | `CreateAppointmentWizard` | Multi-step booking form. |
| Blog List | `/listBlog` | `ListBlogPage` | News feed. |
| Blog Detail | `/blogDetail` | `BlogDetailPage` | Reading view. |

---

## 🚀 11. Deployment Bible

### 11.1 Pre-Flight Checklist
- [ ] **Version Bump:** Increment user version in `pubspec.yaml`.
- [ ] **Environment:** Switch `.env` to Production URLs.
- [ ] **Linting:** Run `flutter analyze` and ensure 0 errors.
- [ ] **Tests:** Run `flutter test` and ensure all green.
- [ ] **Assets:** Ensure all images are optimized.

### 11.2 Android Build
1.  **Keystore:** Ensure `release.jks` is in `android/app/`.
2.  **Properties:** Check `android/key.properties`:
    ```properties
    storePassword=***
    keyPassword=***
    keyAlias=upload
    storeFile=release.jks
    ```
3.  **Command:**
    ```bash
    flutter build appbundle --release
    ```
4.  **Output:** `build/app/outputs/bundle/release/app-release.aab`.

### 11.3 iOS Build
1.  **Certificates:** Open `ios/Runner.xcworkspace` in Xcode.
2.  **Signing:** Select your "Distribution Certificate".
3.  **Command:**
    ```bash
    flutter build ipa --release
    ```
4.  **Upload:** Use "Transporter" app on Mac to upload the `.ipa`.

---

## ❓ 12. Troubleshooting

### "CocoaPods not installed"
*   **Cause:** Missing Ruby gem on Mac.
*   **Fix:**
    ```bash
    sudo gem install cocoapods
    cd ios
    pod install
    ```

### "Conflicting outputs"
*   **Cause:** `build_runner` cache is dirty.
*   **Fix:**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

### "DioError [401]" Loop
*   **Cause:** Refresh token is expired or invalid on server.
*   **Fix:** Clear app data (Settings -> Storage -> Clear Data) to force a fresh login.

### "Keyboard covers input"
*   **Fix:** Wrap the `Column` in a `SingleChildScrollView` or use `ResizeToAvoidBottomInset`.

---

## 📝 13. License

**MIT License**

Copyright (c) 2025 Medicalink Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

> *Managed by the Medicalink Engineering Team.*
