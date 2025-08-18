# Project Summary Report

This report provides an overview of the main components implemented in the project, focusing on the UI, backend connectivity, CRUD operations, landing page design, and data display.

---

## Task Division:

Alexandre:

- Integrate Supabase (authentication + database)
- Integrate persistent Chat History after each query

Dickson:

- Integrate Openrouter (AI Aggregator)
- Update UI

## 1 - UI Interface (Material Design, Activity Flow)

The project adopts **Material 3 Design principles** throughout the interface.

- **AppBar, FAB, Drawer, and Buttons** are styled using Material Design components.
- A **Navigation Drawer** provides quick access to features such as _New Chat_ and _History_.
- **Activity flow**: The user begins at the chat screen, can send/receive messages, view conversation history, and navigate seamlessly between screens.

---

## 2 - Database Connection (Backend Connection)

- Integrated with **Supabase** for authentication and real-time database access.
- Utilizes `supabase_flutter` to handle **anonymous login**, secure queries, and updates.
- The backend stores and retrieves chat records (`chat` table with fields like `cid`, `ctitle`, `cjson`, `cmodified`).

---

## 3 - CRUD Operations – 3%

- **Create**: New chat sessions are stored in Supabase with a generated UUID.
- **Read**: Chat history is fetched and displayed via `FutureBuilder` and `ListView`.
- **Update**: Long-pressing a chat title in the history allows renaming, with changes persisted to Supabase.
- **Delete**: Can be easily extended (confirm dialog → `delete().eq('cid', chatId)`).

---

## 4 - Landing Page (Home Screen)

- The **home screen** is the chat interface (`OpenRouterChatPage`).
- Users can:
  - Enter messages via a **TextField**.
  - Send queries to selected models (DeepSeek, Gemma, GPT-OSS).
  - View responses formatted into **chat bubbles** with distinct styling for user vs. system/assistant messages.

---

## 5 - ListView Implementation (Displaying the Data)

- **Chat messages** are displayed with a `ListView.builder` in a scrollable conversation layout.
- **History page** uses `ListView.separated` wrapped in **Cards**, showing stored chat titles and IDs.
- Each list item supports **onTap** (open chat) and **onLongPress** (update/rename).

---

## Overall

The project delivers a responsive **Material 3 UI**, with robust **Supabase backend connectivity** and full **CRUD functionality** for chat sessions. Users can interact intuitively through the **landing page chat interface**, while data is neatly displayed using `ListView` for both messages and history.
