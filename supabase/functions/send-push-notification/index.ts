// supabase/functions/send-push-notification/index.ts
// Deploy with: supabase functions deploy send-push-notification

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!

serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record

    if (!record || record.is_deleted) {
      return new Response('Skipped', { status: 200 })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Get sender details
    const { data: sender } = await supabase
      .from('users')
      .select('display_name')
      .eq('id', record.sender_id)
      .single()

    // Get all participants except sender
    const { data: participants } = await supabase
      .from('chat_participants')
      .select('user_id, users(fcm_token, is_online)')
      .eq('chat_id', record.chat_id)
      .neq('user_id', record.sender_id)

    if (!participants || participants.length === 0) {
      return new Response('No recipients', { status: 200 })
    }

    const tokens = participants
      .map((p: any) => p.users?.fcm_token)
      .filter(Boolean)

    if (tokens.length === 0) {
      return new Response('No tokens', { status: 200 })
    }

    // Build notification body
    let body = record.content || ''
    if (record.type === 'image') body = '📷 Photo'
    else if (record.type === 'audio') body = '🎤 Voice message'
    else if (record.type === 'video') body = '🎥 Video'
    else if (record.type === 'document') body = '📄 Document'

    // Send FCM
    const fcmPayload = {
      registration_ids: tokens,
      notification: {
        title: sender?.display_name ?? 'Chatter',
        body,
        sound: 'default',
        badge: '1',
      },
      data: {
        chatId: record.chat_id,
        messageId: record.id,
        senderId: record.sender_id,
        type: record.type,
      },
      priority: 'high',
      content_available: true,
    }

    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify(fcmPayload),
    })

    const result = await fcmResponse.json()
    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
