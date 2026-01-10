import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { create } from "https://deno.land/x/djwt@v2.8/mod.ts"

serve(async (req) => {
  try {
    const payload = await req.json()
    const post = payload.record 
    const userId = post.user_id

    // 1. Ambil Secrets dari Supabase Dashboard
    const projectId = Deno.env.get('FCM_PROJECT_ID')
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
    const privateKey = Deno.env.get('FCM_PRIVATE_KEY')?.replace(/\\n/g, '\n')

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Ambil username pengirim status
    const { data: creator } = await supabaseAdmin
      .from('profiles')
      .select('username')
      .eq('id', userId)
      .single()

    // 3. Cari teman-teman yang sudah berteman (accepted)
    const { data: friends } = await supabaseAdmin
      .from('friendships')
      .select('from_user_id, to_user_id')
      .eq('status', 'accepted')
      .or(`from_user_id.eq.${userId},to_user_id.eq.${userId}`)

    const friendIds = friends?.map(f => f.from_user_id === userId ? f.to_user_id : f.from_user_id) || []
    
    if (friendIds.length === 0) return new Response("No friends to notify")

    // 4. Ambil Token FCM (HP) milik teman-teman tersebut
    const { data: profiles } = await supabaseAdmin
      .from('profiles')
      .select('fcm_token')
      .in('id', friendIds)
      .not('fcm_token', 'is', null)

    const tokens = profiles?.map(p => p.fcm_token) || []
    if (tokens.length === 0) return new Response("No tokens found")

    // 5. Autentikasi Google (FCM v1) menggunakan Secrets
    const jwt = await create({ alg: "RS256", typ: "JWT" }, {
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/cloud-platform",
      aud: "https://oauth2.googleapis.com/token",
      exp: Math.floor(Date.now() / 1000) + 3600,
      iat: Math.floor(Date.now() / 1000),
    }, await crypto.subtle.importKey(
      "pkcs8",
      new Uint8Array(atob(privateKey!.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, '')).split('').map(c => c.charCodeAt(0))),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    ))

    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    })
    const { access_token } = await tokenRes.json()

    // 6. Kirim Notifikasi ke semua teman dengan kalimat premium
    const username = creator?.username ?? 'Seorang teman'
    const notificationResults = await Promise.all(tokens.map(token => 
      fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${access_token}`,
        },
        body: JSON.stringify({
          message: {
            token: token,
            notification: {
              title: "FLOW Moments",
              body: `${username} baru saja membagikan momen baru! ✨`
            },
            android: {
              notification: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                sound: "default"
              }
            }
          }
        })
      })
    ))

    return new Response(JSON.stringify({ success: true, notified: notificationResults.length }), { headers: { "Content-Type": "application/json" } })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { "Content-Type": "application/json" } })
  }
})
