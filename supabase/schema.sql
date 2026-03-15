-- ============================================================
-- CHATTER — Supabase Database Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. USERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         TEXT UNIQUE,
  email         TEXT UNIQUE,
  username      TEXT UNIQUE NOT NULL,
  display_name  TEXT NOT NULL,
  avatar_url    TEXT,
  status_msg    TEXT DEFAULT 'Hey there! I am using Chatter.',
  last_seen     TIMESTAMPTZ DEFAULT NOW(),
  is_online     BOOLEAN DEFAULT FALSE,
  fcm_token     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users: anyone can read"
  ON users FOR SELECT USING (true);

CREATE POLICY "Users: only owner can update"
  ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users: authenticated can insert own row"
  ON users FOR INSERT WITH CHECK (auth.uid() = id);


-- ────────────────────────────────────────────────────────────
-- 2. CHATS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chats (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type         TEXT NOT NULL CHECK (type IN ('direct', 'group')),
  name         TEXT,
  avatar_url   TEXT,
  description  TEXT,
  last_message TEXT,
  last_msg_at  TIMESTAMPTZ,
  created_by   UUID REFERENCES users(id),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chats: only participants can read"
  ON chats FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM chat_participants WHERE chat_id = id
    )
  );

CREATE POLICY "Chats: authenticated users can create"
  ON chats FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Chats: creator or admin can update"
  ON chats FOR UPDATE USING (
    auth.uid() = created_by OR
    auth.uid() IN (
      SELECT user_id FROM chat_participants
      WHERE chat_id = id AND role = 'admin'
    )
  );


-- ────────────────────────────────────────────────────────────
-- 3. CHAT PARTICIPANTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_participants (
  chat_id    UUID REFERENCES chats(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  role       TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin')),
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);

ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants: only members can read"
  ON chat_participants FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM chat_participants cp WHERE cp.chat_id = chat_id
    )
  );

CREATE POLICY "Participants: admin can insert"
  ON chat_participants FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM chat_participants
      WHERE chat_id = chat_participants.chat_id AND role = 'admin'
    ) OR
    auth.uid() = (SELECT created_by FROM chats WHERE id = chat_participants.chat_id)
  );

CREATE POLICY "Participants: admin can delete"
  ON chat_participants FOR DELETE USING (
    auth.uid() = user_id OR
    auth.uid() IN (
      SELECT user_id FROM chat_participants cp
      WHERE cp.chat_id = chat_id AND cp.role = 'admin'
    )
  );


-- ────────────────────────────────────────────────────────────
-- 4. MESSAGES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id     UUID REFERENCES chats(id) ON DELETE CASCADE,
  sender_id   UUID REFERENCES users(id),
  content     TEXT,
  type        TEXT NOT NULL CHECK (
                type IN ('text','image','video','audio','document','location')
              ),
  media_url   TEXT,
  reply_to_id UUID REFERENCES messages(id),
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Messages: only participants can read"
  ON messages FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM chat_participants WHERE chat_id = messages.chat_id
    )
  );

CREATE POLICY "Messages: participants can insert"
  ON messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    auth.uid() IN (
      SELECT user_id FROM chat_participants WHERE chat_id = messages.chat_id
    )
  );

CREATE POLICY "Messages: sender can soft-delete"
  ON messages FOR UPDATE USING (auth.uid() = sender_id);


-- ────────────────────────────────────────────────────────────
-- 5. MESSAGE STATUS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS message_status (
  message_id  UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES users(id),
  status      TEXT CHECK (status IN ('delivered', 'read')),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (message_id, user_id)
);

ALTER TABLE message_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Status: user can read own"
  ON message_status FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Status: user can upsert own"
  ON message_status FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Status: user can update own"
  ON message_status FOR UPDATE USING (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────
-- 6. INDEXES
-- ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat ON chat_participants(chat_id);
CREATE INDEX IF NOT EXISTS idx_chats_last_msg_at ON chats(last_msg_at DESC);


-- ────────────────────────────────────────────────────────────
-- 7. HELPER FUNCTION — get_direct_chat
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_direct_chat(user1_id UUID, user2_id UUID)
RETURNS chats AS $$
DECLARE
  result chats;
BEGIN
  SELECT c.* INTO result
  FROM chats c
  WHERE c.type = 'direct'
    AND EXISTS (
      SELECT 1 FROM chat_participants cp1
      WHERE cp1.chat_id = c.id AND cp1.user_id = user1_id
    )
    AND EXISTS (
      SELECT 1 FROM chat_participants cp2
      WHERE cp2.chat_id = c.id AND cp2.user_id = user2_id
    )
  LIMIT 1;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ────────────────────────────────────────────────────────────
-- 8. STORAGE BUCKETS (run separately in Supabase dashboard or via API)
-- ────────────────────────────────────────────────────────────
-- INSERT INTO storage.buckets (id, name, public)
--   VALUES ('avatars', 'avatars', true)
--   ON CONFLICT DO NOTHING;

-- INSERT INTO storage.buckets (id, name, public)
--   VALUES ('chat-media', 'chat-media', false)
--   ON CONFLICT DO NOTHING;

-- INSERT INTO storage.buckets (id, name, public)
--   VALUES ('group-icons', 'group-icons', true)
--   ON CONFLICT DO NOTHING;


-- ────────────────────────────────────────────────────────────
-- 9. REALTIME — enable on tables
-- ────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE message_status;


-- ────────────────────────────────────────────────────────────
-- 10. EDGE FUNCTION TRIGGER — push notifications
-- ────────────────────────────────────────────────────────────
-- After deploying your Edge Function "send-push-notification", 
-- create a database webhook in Supabase Dashboard:
--   Table: messages
--   Events: INSERT
--   URL: https://<project>.supabase.co/functions/v1/send-push-notification
