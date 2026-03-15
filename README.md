<div align="center">

<br/>

<img src="https://readme-typing-svg.demolab.com?font=Plus+Jakarta+Sans&weight=700&size=32&pause=1000&color=FFEB3B&center=true&vCenter=true&width=435&lines=%E2%9D%A4%EF%B8%8F+Heartbeat" alt="Heartbeat" />

<br/>

**Real-time chat. Built with Flutter & Supabase.**

<br/>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-2.x-3ECF8E?style=flat-square&logo=supabase&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey?style=flat-square)


*A cross-platform messaging app with real-time delivery, offline support,*
*voice messages, group chats, and a warm amber design system.*


[Features](#-features) · [Getting Started](#-getting-started) · [Structure](#-project-structure) · [Architecture](#-architecture) · [Design](#-design-system)

---

</div>


## ✦ Features
<div align="center">
<table width="100%">
<tr>
<th width="15%">Category</th>
<th width="70%">Feature</th>
<th width="15%" align="center">Status</th>
</tr>
<tr><td rowspan="3"><b>Auth</b></td><td>Email & password sign up / sign in</td><td align="center">✅</td></tr>
<tr><td>Phone OTP verification</td><td align="center">✅</td></tr>
<tr><td>Google OAuth</td><td align="center">🔜</td></tr>
<tr><td rowspan="6"><b>Messaging</b></td><td>1-to-1 real-time chat</td><td align="center">✅</td></tr>
<tr><td>Group chats (create, manage, admin roles)</td><td align="center">✅</td></tr>
<tr><td>Delivery & read receipts (✓ ✓✓ 🔵)</td><td align="center">✅</td></tr>
<tr><td>Typing indicators</td><td align="center">✅</td></tr>
<tr><td>Reply to messages</td><td align="center">✅</td></tr>
<tr><td>Delete for self / everyone</td><td align="center">✅</td></tr>
<tr><td rowspan="3"><b>Media</b></td><td>Image & video sharing</td><td align="center">✅</td></tr>
<tr><td>Voice messages (hold to record)</td><td align="center">✅</td></tr>
<tr><td>Document sharing (PDF, DOCX, XLSX)</td><td align="center">✅</td></tr>
<tr><td rowspan="4"><b>UX</b></td><td>Offline message queue + cache</td><td align="center">✅</td></tr>
<tr><td>Optimistic UI (instant send)</td><td align="center">✅</td></tr>
<tr><td>Dark mode</td><td align="center">✅</td></tr>
<tr><td>Swipe to reply</td><td align="center">✅</td></tr>
<tr><td rowspan="4"><b>Coming Soon</b></td><td>Push notifications (FCM / APNs)</td><td align="center">🔜</td></tr>
<tr><td>Voice & video calls (WebRTC)</td><td align="center">🔜</td></tr>
<tr><td>Message reactions</td><td align="center">🔜</td></tr>
<tr><td>End-to-end encryption</td><td align="center">🔜</td></tr>
</table>
</div>


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

2. Open the **SQL Editor** and run `supabase/schema.sql` in **two steps**:
   - **Step 1** — paste and run the tables block first
   - **Step 2** — paste and run the RLS policies block second

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

Or paste directly into `lib/core/constants/supabase_constants.dart`:

```dart
static const String supabaseUrl     = 'https://YOUR_PROJECT.supabase.co';
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

> Keep the terminal open while developing.
> Press `r` to hot reload · `R` to hot restart · `q` to quit


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
│       └── send-push-notification/  ← Edge function (Deno / TypeScript)
│
├── android/
├── ios/
├── test/
├── .env                        ← 🔒 gitignored — your secrets here
├── .gitignore
└── pubspec.yaml
```



---


## ✦ Database Schema


```
users               id · phone · email · username · display_name
                    avatar_url · status_msg · last_seen · is_online

chats               id · type (direct|group) · name · avatar_url
                    last_message · last_msg_at · created_by

chat_participants   chat_id · user_id · role (member|admin) · joined_at

messages            id · chat_id · sender_id · content · type
                    media_url · reply_to_id · is_deleted · created_at

message_status      message_id · user_id · status (delivered|read) · updated_at
```

> Row-Level Security is enabled on all tables — users can only read and write data they are authorised to access.


---


## ✦ Environment Variables


| Variable | Location | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | `.env` or `supabase_constants.dart` | Supabase project URL |
| `SUPABASE_ANON_KEY` | `.env` or `supabase_constants.dart` | Supabase public anon key |

---



<div align="center">

Made with ❤️ by Kunal

</div>
