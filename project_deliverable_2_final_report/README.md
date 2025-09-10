# Inforno — Course Deliverable

A compact summary of our project status against the course deliverables, with setup/run steps and a task-distribution document you can hand in.

## 1. Project Aim & Description

Inforno is a Flutter chat client that lets a user authenticate (email/password, magic link/socials, and phone OTP), then message multiple LLMs in parallel via the OpenRouter API. Messages and chat titles are stored in Supabase. Initially, we wanted to add a payment system so that user who has subscribes to multiple AI Search Engine can subscribe to ours where we can provide all AI Search engines. So, we went with a fancy AI aggregator search engine for personal use.

Tech stack: Flutter, Dart, Supabase (Auth + Postgres), OpenRouter (HTTP/JSON), Material 3 UI.

Why: Demonstrate a complete mobile app flow (auth → navigation → async API calls → persistence) suitable for this final deliverable.

## 2. Feature Summary

### UI / Navigation flow

We implemented a clean navigation structure with 8 primary screens:

- Auth (email/password sign-in)
- Register / Magic Link & Socials
- Phone Auth (SMS OTP)
- New Chat (seed a conversation)
- Chat (parallel responses from multiple models)
- History (saved chats from Supabase)
- Model Picker (select which models reply)
- Settings (theme toggle, sign out)

### API calls (JSON, Async, Threading)

- All chat calls are raw HTTP/JSON.
- We dispatch parallel requests to multiple models using Future.wait, demonstrating asynchrony/concurrency.
- Basic error handling and UI loading states are included.

### Notification manager

Not implemented.

Rationale: The plugin path required core library desugaring and a Kotlin/AGP upgrade. We deferred to avoid destabilizing the build before the presentation. We had no intentation of adding this feature during the planning process.

### Authentication (Email, SMS, call)

- Email/password, reset password.
- Magic link and socials (Google/Apple via Supabase Auth UI).
- Phone SMS OTP (verify code flow).
- Anonymous sign-in for a quick demo path.

### Location awareness (Google Maps, places, address)

Not implemented.

Rationale: Maps + geolocation also required platform config and version upgrades; we parked this to keep the build stable. Like the notification manager, we had no intentation of adding this feature during the planning process.

### Running on an emulator

Tested on Android emulator; iOS Simulator runs with the same Flutter entry point (team provisioning needed to sign if using device features).

## 3. How to Run

#### Prerequisites

- Flutter SDK (stable channel)
- A Supabase project (we use our own URL + anon key)
- An OpenRouter API key

#### Environment

- Create a .env file at the repo root:
- Add OPENROUTER_API_KEY=your_openrouter_api_key_here

Supabase URL and anon key are set in main(); if you fork, replace them with yours.

#### Install & Run

- flutter clean
- flutter pub get
- flutter run
- pick your device

## 4. Functional & Non-Functional Requirements

- Users can sign in (email/password), register via magic link/socials, or use SMS OTP.
- Users can start a chat; the app fans out the request to selected models.
- Responses stream back and are appended to the conversation.
- Chats are persisted to Supabase (title + JSON transcript).
- Users can view history and reopen a conversation.
- Users can pick models via a dedicated UI.

- Clear loading/error states for network calls.
- Material 3 theming (light/dark toggle).
- Stateless navigation structure for predictable back behavior.
- Minimal dependencies to reduce platform build friction.

## 5. User Stories (Samples)

- As a new user, I want to sign up quickly (magic link/socials) so I can try the app without a long form.
- As a returning user, I want to resume earlier chats from History so I don’t lose context.
- As a power user, I want to choose which models reply so I can compare answers side-by-side.
- As a guest, I want to try the app without creating an account to see if it fits my needs.

## 6. Known Limitations / Deferred Items

Notifications (local) — deferred. Would require enabling core library desugaring and upgrading Kotlin/AGP; risked breaking other builds pre-presentation.

Maps/Places — deferred. Requires Maps key + platform setup and location permissions; also implicated build upgrades.

10-screen minimum. We currently ship 8. If strictly required, we can add “About” and “Help/FAQ” (or “Profile” and “Support”) with minimal code changes.

## 7. Future Work

- Add local notifications via flutter_local_notifications after enabling desugaring and upgrading Kotlin/AGP.
- Add Maps & Places (current location + reverse geocode) with google_maps_flutter and geolocator.
- Message streaming UI and per-message feedback.
- Basic analytics and crash reporting.
