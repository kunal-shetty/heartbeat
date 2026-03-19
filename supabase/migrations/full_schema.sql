-- ============================================================
-- Heartbeat · Full schema migration
-- Run this in Supabase SQL Editor.
-- ============================================================

-- ───────────────────────────────────────────────────────────
-- 1. RLS POLICIES for existing tables
-- ───────────────────────────────────────────────────────────

-- Enable RLS
ALTER TABLE public.users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_status   ENABLE ROW LEVEL SECURITY;

-- users: anyone authenticated can read; only owner can update
CREATE POLICY "users_select" ON public.users
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "users_update" ON public.users
  FOR UPDATE TO authenticated USING (auth.uid() = id);

-- chats: participants can read
CREATE POLICY "chats_select" ON public.chats
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants
      WHERE chat_id = id AND user_id = auth.uid()
    )
  );

CREATE POLICY "chats_insert" ON public.chats
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

CREATE POLICY "chats_update" ON public.chats
  FOR UPDATE TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants
      WHERE chat_id = id AND user_id = auth.uid()
    )
  );

-- chat_participants: members can read their own rows
CREATE POLICY "cp_select" ON public.chat_participants
  FOR SELECT TO authenticated USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.chat_participants cp2
      WHERE cp2.chat_id = chat_id AND cp2.user_id = auth.uid()
    )
  );

CREATE POLICY "cp_insert" ON public.chat_participants
  FOR INSERT TO authenticated WITH CHECK (true);

-- messages: chat participants can read/insert
CREATE POLICY "messages_select" ON public.messages
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants
      WHERE chat_id = messages.chat_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "messages_insert" ON public.messages
  FOR INSERT TO authenticated WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM public.chat_participants
      WHERE chat_id = messages.chat_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "messages_update" ON public.messages
  FOR UPDATE TO authenticated USING (auth.uid() = sender_id);

-- message_status: participants can read/write
CREATE POLICY "ms_select" ON public.message_status
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "ms_upsert" ON public.message_status
  FOR ALL TO authenticated USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ───────────────────────────────────────────────────────────
-- 2. STATUS UPDATES TABLE
-- ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.status_updates (
  id           uuid    NOT NULL DEFAULT gen_random_uuid(),
  user_id      uuid    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  media_url    text    NOT NULL,                 -- image stored in 'status-media' bucket
  caption      text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL DEFAULT (now() + INTERVAL '24 hours'),
  views        integer NOT NULL DEFAULT 0,
  CONSTRAINT status_updates_pkey PRIMARY KEY (id)
);

ALTER TABLE public.status_updates ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can view non-expired statuses
CREATE POLICY "status_select" ON public.status_updates
  FOR SELECT TO authenticated USING (expires_at > now());

-- Only owner can insert/delete
CREATE POLICY "status_insert" ON public.status_updates
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "status_delete" ON public.status_updates
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ───────────────────────────────────────────────────────────
-- 3. STATUS VIEWS TABLE (who viewed whose status)
-- ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.status_views (
  status_id  uuid NOT NULL REFERENCES public.status_updates(id) ON DELETE CASCADE,
  viewer_id  uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  viewed_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT status_views_pkey PRIMARY KEY (status_id, viewer_id)
);

ALTER TABLE public.status_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sv_select" ON public.status_views
  FOR SELECT TO authenticated USING (viewer_id = auth.uid());

CREATE POLICY "sv_insert" ON public.status_views
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = viewer_id);

-- ───────────────────────────────────────────────────────────
-- 4. CALLS TABLE
-- ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.calls (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  chat_id     uuid    REFERENCES public.chats(id) ON DELETE SET NULL,
  caller_id   uuid    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  callee_id   uuid    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        text    NOT NULL CHECK (type IN ('audio', 'video')),
  status      text    NOT NULL DEFAULT 'missed' CHECK (status IN ('answered', 'missed', 'declined', 'ongoing')),
  started_at  timestamptz,
  ended_at    timestamptz,
  duration_s  integer,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT calls_pkey PRIMARY KEY (id)
);

ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "calls_select" ON public.calls
  FOR SELECT TO authenticated
  USING (auth.uid() = caller_id OR auth.uid() = callee_id);

CREATE POLICY "calls_insert" ON public.calls
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = caller_id);

CREATE POLICY "calls_update" ON public.calls
  FOR UPDATE TO authenticated
  USING (auth.uid() = caller_id OR auth.uid() = callee_id);

-- ───────────────────────────────────────────────────────────
-- 5. Helper RPC: get_direct_chat
-- ───────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_direct_chat(user1_id uuid, user2_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT c.id
  FROM public.chats c
  JOIN public.chat_participants cp1 ON cp1.chat_id = c.id AND cp1.user_id = user1_id
  JOIN public.chat_participants cp2 ON cp2.chat_id = c.id AND cp2.user_id = user2_id
  WHERE c.type = 'direct'
  LIMIT 1;
$$;

-- ───────────────────────────────────────────────────────────
-- 6. Storage buckets
-- ───────────────────────────────────────────────────────────

-- Create buckets (run from dashboard Storage tab OR via SQL)
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars',      'avatars',      true),
  ('chat-media',   'chat-media',   false),
  ('group-icons',  'group-icons',  true),
  ('status-media', 'status-media', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies: avatars are public read, owner-write
CREATE POLICY "avatars_read"   ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "avatars_write"  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "chat_media_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'chat-media');
CREATE POLICY "chat_media_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'chat-media');

CREATE POLICY "status_media_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'status-media');
CREATE POLICY "status_media_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'status-media' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "group_icons_read"  ON storage.objects FOR SELECT USING (bucket_id = 'group-icons');
CREATE POLICY "group_icons_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'group-icons');

-- ───────────────────────────────────────────────────────────
-- 7. Realtime: enable for tables that need live updates
-- ───────────────────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
ALTER PUBLICATION supabase_realtime ADD TABLE public.status_updates;
ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
