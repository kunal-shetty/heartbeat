    <div align="center">

    <br/>


    ### ❤️  Heartbeat

    ### *Real-time chat. Built with Flutter & Supabase.*

    <br/>

    ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)
    ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)
    ![Supabase](https://img.shields.io/badge/Supabase-2.x-3ECF8E?style=flat-square&logo=supabase&logoColor=white)

    <br/>

    > A cross-platform messaging app with real-time delivery, offline support,  
    > voice messages, group chats, and a warm amber design system.

    <br/>

    ---

    </div>


    ## ✦ Features

    <br/>

    | Category | Feature | Status |
    |----------|---------|:------:|
    | **Auth** | Email & password sign up / sign in | ✅ |
    | | Phone OTP verification | ✅ |
    | | Google OAuth | 🔜 |
    | **Messaging** | 1-to-1 real-time chat | ✅ |
    | | Group chats (create, manage, admin roles) | ✅ |
    | | Delivery & read receipts (✓ ✓✓ 🔵) | ✅ |
    | | Typing indicators | ✅ |
    | | Reply to messages | ✅ |
    | | Delete for self / everyone | ✅ |
    | **Media** | Image & video sharing | ✅ |
    | | Voice messages (hold to record) | ✅ |
    | | Document sharing (PDF, DOCX, XLSX) | ✅ |
    | **UX** | Offline message queue + cache | ✅ |
    | | Optimistic UI (instant send) | ✅ |
    | | Dark mode | ✅ |
    | | Swipe to reply | ✅ |
    | **Coming Soon** | Push notifications | 🔜 |
    | | Voice & video calls (WebRTC) | 🔜 |
    | | Message reactions | 🔜 |
    | | End-to-end encryption | 🔜 |

    <br/>

    ---

    ## ✦ Getting Started

    ### Prerequisites

    ```bash
    flutter --version   # Flutter 3.x required
    dart --version      # Dart 3.x required
    ```

    ### 1 · Clone & install

    ```bash
    git clone https://github.com/your-org/heartbeat.git
    cd heartbeat
    flutter pub get
    ```

    ### 2 · Set up Supabase

    1. Create a project at [supabase.com](https://supabase.com)

    2. Open the **SQL Editor** and run `supabase/schema.sql` in two steps:
    - **Step 1** — paste and run the tables block first
    - **Step 2** — paste and run the RLS policies block second  
        *(policies reference `chat_participants`, so tables must exist first)*

    3. Create Storage buckets:

    | Bucket | Access |
    |--------|--------|
    | `avatars` | Public |
    | `chat-media` | Private |
    | `group-icons` | Public |

    4. In **Authentication → URL Configuration** set:
    ```
    Site URL:     com.example.heartbeat://login-callback
    Redirect URL: com.example.heartbeat://login-callback
    ```

    5. Copy your **Project URL** and **Anon Key**


    ### 3 · Configure credentials

    Create a `.env` file in the project root:

    ```env
    SUPABASE_URL=https://YOUR_PROJECT.supabase.co
    SUPABASE_ANON_KEY=YOUR_ANON_KEY
    ```

    Or paste them directly into `lib/core/constants/supabase_constants.dart`:

    ```dart
    static const String supabaseUrl    = 'https://YOUR_PROJECT.supabase.co';
    static const String supabaseAnonKey = 'YOUR_ANON_KEY';
    ```

    ### 4 · Run

    ```bash
    # Android
    flutter run

    # iOS — install pods first
    cd ios && pod install && cd ..
    flutter run

    # Web
    flutter run -d chrome
    ```

    > Keep the terminal open while developing. Press `r` to hot reload, `R` to hot restart.

    ---



    ## ✦ Project Structure


    ```
    heartbeat/
    │
    ├── lib/
    │   ├── core/
    │   │   ├── constants/          ← Supabase config, app-wide constants
    │   │   ├── errors/             ← Failure types
    │   │   ├── router/             ← GoRouter navigation
    │   │   ├── theme/              ← Amber design system (AppTheme)
    │   │   └── utils/              ← Extensions (DateTime, String, Context)
    │   │
    │   ├── features/
    │   │   ├── auth/
    │   │   │   ├── data/           ← Supabase datasource, repository impl
    │   │   │   ├── domain/         ← UserEntity, use cases, repository interface
    │   │   │   └── presentation/   ← AuthBloc, Login, Register, OTP screens
    │   │   │
    │   │   ├── chat/
    │   │   │   ├── data/           ← Remote (Supabase) + Local (SharedPreferences)
    │   │   │   ├── domain/         ← ChatEntity, MessageEntity, use cases
    │   │   │   └── presentation/   ← ChatListBloc, ChatBloc, screens, widgets
    │   │   │
    │   │   ├── profile/            ← View & edit profile, avatar upload
    │   │   ├── groups/             ← Create group, participant picker, group info
    │   │   └── calls/              ← Call screen (WebRTC — coming soon)
    │   │
    │   ├── shared/
    │   │   ├── widgets/            ← UserAvatar
    │   │   └── services/           ← StorageService, ConnectivityService
    │   │
    │   ├── injection_container.dart  ← GetIt dependency injection
    │   └── main.dart
    │
    ├── supabase/
    │   ├── schema.sql              ← Full DB schema + RLS policies
    │   └── functions/
    │       └── send-push-notification/   ← Edge function (Deno/TypeScript)
    │
    ├── android/
    ├── ios/
    ├── .env                        ← gitignored — your secrets go here
    └── pubspec.yaml
    ```

    <br/>

    ---

    **Key patterns:**

    - **Clean Architecture** — strict separation of Presentation, Domain, Data
    - **BLoC** — all state via `flutter_bloc`, events in / states out
    - **Offline-first** — every remote response is cached locally; app works without network
    - **Optimistic UI** — messages render instantly with `pending` status, confirmed on ACK
    - **Repository pattern** — domain layer never touches Supabase directly

    ---

    ## ✦ Design System

    Heartbeat uses a warm **Amber / Orange** palette. All tokens live in `lib/core/theme/app_theme.dart`.

    ```
    Amber 500   #F59E0B  ████  App bar · FAB · primary buttons · active tabs
    Amber 600   #D97706  ████  Pressed states
    Amber 800   #92400E  ████  Headings on light backgrounds
    Amber 50    #FEF3C7  ████  Sent message bubble · input field fill
    Orange 600  #EA580C  ████  FAB · mic button · call-to-action accents
    Stone 900   #1C1917  ████  Primary body text
    Stone 400   #A8A29E  ████  Timestamps · placeholder · metadata
    Green 500   #22C55E  ████  Online indicator dot
    Blue 500    #3B82F6  ████  Read receipt (double tick)
    Red 500     #EF4444  ████  Errors · delete actions
    ```

    **Typography**
    - `Plus Jakarta Sans` — display, headings, UI labels
    - `Inter` — timestamps, status text, metadata

    ---

    ## ✦ Realtime & Presence

    Messages use **Supabase Realtime** (Postgres CDC over WebSockets):

    ```dart
    supabase
    .channel('chat:$chatId')
    .onPostgresChanges(
        event:  PostgresChangeEvent.insert,
        schema: 'public',
        table:  'messages',
        filter: PostgresChangeFilter(
        type:   PostgresChangeFilterType.eq,
        column: 'chat_id',
        value:  chatId,
        ),
        callback: (payload) {
        chatBloc.add(ChatNewMessageEvent(_mapMessage(payload.newRecord)));
        },
    )
    .subscribe();
    ```

    Typing indicators use **Supabase Presence**:

    ```dart
    // Broadcast typing state
    await channel.track({'user_id': userId, 'typing': true});

    // Listen for others typing
    channel.onPresenceSync((_) {
    final presences = channel.presenceState();
    // update typing indicator UI
    });
    ```

    ---


    ## ✦ Database Schema

    ```
    users
    id · phone · email · username · display_name
    avatar_url · status_msg · last_seen · is_online

    chats
    id · type (direct|group) · name · avatar_url
    last_message · last_msg_at · created_by

    chat_participants
    chat_id · user_id · role (member|admin) · joined_at

    messages
    id · chat_id · sender_id · content · type
    media_url · reply_to_id · is_deleted · created_at

    message_status
    message_id · user_id · status (delivered|read) · updated_at
    ```

    Row-Level Security is enabled on all tables — users can only read and write data they are authorised to access.

    ---

    ## ✦ Environment Variables

    | Variable | Location | Description |
    |----------|----------|-------------|
    | `SUPABASE_URL` | `.env` or `supabase_constants.dart` | Supabase project URL |
    | `SUPABASE_ANON_KEY` | `.env` or `supabase_constants.dart` | Supabase public anon key |

