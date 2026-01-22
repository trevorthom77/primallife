import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

  const textEncoder = new TextEncoder()

  function isoToFlag(iso: string | null | undefined): string {
    if (!iso) return ''
    const code = iso.trim().toUpperCase()
    if (!/^[A-Z]{2}$/.test(code)) return ''
    const first = code.codePointAt(0)
    const second = code.codePointAt(1)
    if (first == null || second == null) return ''
    return String.fromCodePoint(
      0x1f1e6 + first - 65,
      0x1f1e6 + second - 65,
    )
  }

  function base64UrlEncode(data: Uint8Array): string {
    let binary = ''
    for (let i = 0; i < data.length; i++) {
      binary += String.fromCharCode(data[i])
    }
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g,
  '')
  }

  function pemToArrayBuffer(pem: string): ArrayBuffer {
    const cleaned = pem
      .replace(/-----BEGIN PRIVATE KEY-----/g, '')
      .replace(/-----END PRIVATE KEY-----/g, '')
      .replace(/\s+/g, '')
    const binary = atob(cleaned)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i)
    }
    return bytes.buffer
  }

  async function createApnsJwt(
    teamId: string,
    keyId: string,
    privateKeyPem: string,
  ): Promise<string> {
    const keyData = pemToArrayBuffer(privateKeyPem)
    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      keyData,
      { name: 'ECDSA', namedCurve: 'P-256' },
      false,
      ['sign'],
    )

    const header = { alg: 'ES256', kid: keyId, typ: 'JWT' }
    const payload = { iss: teamId, iat: Math.floor(Date.now() / 1000) }

    const headerPart =
  base64UrlEncode(textEncoder.encode(JSON.stringify(header)))
    const payloadPart =
  base64UrlEncode(textEncoder.encode(JSON.stringify(payload)))
    const signingInput = `${headerPart}.${payloadPart}`

    const signature = await crypto.subtle.sign(
      { name: 'ECDSA', hash: 'SHA-256' },
      cryptoKey,
      textEncoder.encode(signingInput),
    )

    const signaturePart = base64UrlEncode(new Uint8Array(signature))
    return `${signingInput}.${signaturePart}`
  }

  type ApnsAlert = string | { title: string; body: string }

  async function sendPush(
    token: string,
    alert: ApnsAlert,
    host: string,
    topic: string,
    jwt: string,
  ) {
    const res = await fetch(`https://${host}/3/device/${token}`, {
      method: 'POST',
      headers: {
        authorization: `bearer ${jwt}`,
        'apns-topic': topic,
        'apns-push-type': 'alert',
        'content-type': 'application/json',
      },
      body: JSON.stringify({ aps: { alert } }),
    })

    if (!res.ok) {
      const body = await res.text().catch(() => '')
      console.error('APNS error', res.status, body)
    }
  }

  Deno.serve(async (req) => {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const apnsTeamId = Deno.env.get('APNS_TEAM_ID')
    const apnsKeyId = Deno.env.get('APNS_KEY_ID')
    const apnsBundleId = Deno.env.get('APNS_BUNDLE_ID')
    const apnsPrivateKey = Deno.env.get('APNS_PRIVATE_KEY')?.replace(/\\n/g,
  '\n')
    const apnsHost = Deno.env.get('APNS_HOST')

    if (
      !supabaseUrl ||
      !serviceRoleKey ||
      !apnsTeamId ||
      !apnsKeyId ||
      !apnsBundleId ||
      !apnsPrivateKey ||
      !apnsHost
    ) {
      console.error('Missing env config')
      return new Response('Server not configured', { status: 500 })
    }

    let payload: any
    try {
      payload = await req.json()
    } catch {
      return new Response('Invalid payload', { status: 400 })
    }

    const { type, record, old_record: oldRecord } = payload ?? {}
    if (!record) {
      return new Response('No record', { status: 400 })
    }

    const table = payload?.table as string | undefined
    const status = record.status as string | undefined
    const requesterId = record.requester_id as string | undefined
    const receiverId = record.receiver_id as string | undefined

    let targetUserId: string | null = null
    let alert: ApnsAlert | null = null

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const senderId = record.sender_id as string | undefined
    const friendId = record.friend_id as string | undefined
    const messageText = record.text as string | undefined
    const isFriendMessageInsert =
      type === 'INSERT' &&
      (table === 'friend_messages' || (!!senderId && !!friendId))

    if (isFriendMessageInsert && senderId && friendId) {
      const { data } = await supabase
        .from('onboarding')
        .select('full_name, origin')
        .eq('id', senderId)
        .maybeSingle()

      const senderName = data?.full_name ?? ''
      const senderFlag = isoToFlag(data?.origin)
      const senderPrefix = senderFlag ? `${senderFlag} ` : ''
      targetUserId = friendId
      alert = {
        title: `${senderPrefix}${senderName}`,
        body: messageText ?? '',
      }
    } else if (
      type === 'INSERT' &&
      status === 'pending' &&
      requesterId &&
      receiverId
    ) {
      const { data } = await supabase
        .from('onboarding')
        .select('full_name, origin')
        .eq('id', requesterId)
        .maybeSingle()

      const requesterName = data?.full_name ?? ''
      const requesterFlag = isoToFlag(data?.origin)
      const requesterPrefix = requesterFlag ? `${requesterFlag} ` : ''
      targetUserId = receiverId
      alert = `${requesterPrefix}${requesterName} added you`
    } else if (
      type === 'UPDATE' &&
      status === 'accepted' &&
      oldRecord?.status !== 'accepted' &&
      requesterId &&
      receiverId
    ) {
      const { data } = await supabase
        .from('onboarding')
        .select('full_name, origin')
        .eq('id', receiverId)
        .maybeSingle()

      const receiverName = data?.full_name ?? ''
      const receiverFlag = isoToFlag(data?.origin)
      const receiverPrefix = receiverFlag ? `${receiverFlag} ` : ''
      targetUserId = requesterId
      alert = `${receiverPrefix}${receiverName} accepted your request`
    } else {
      return new Response(JSON.stringify({ ignored: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { data: tokens } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('id', targetUserId)

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ ok: true, sent: 0 }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const apnsJwt = await createApnsJwt(apnsTeamId, apnsKeyId, apnsPrivateKey)

    await Promise.all(
      tokens
        .map((row: { token: string | null }) => row.token)
        .filter((token: string | null): token is string => !!token)
        .map((token: string) =>
          sendPush(token, alert ?? '', apnsHost, apnsBundleId, apnsJwt),
        ),
    )

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
