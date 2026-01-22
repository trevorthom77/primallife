import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const textEncoder = new TextEncoder()

function base64UrlEncode(data: Uint8Array): string {
  let binary = ''
  for (let i = 0; i < data.length; i++) {
    binary += String.fromCharCode(data[i])
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '')
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

  const headerPart = base64UrlEncode(textEncoder.encode(JSON.stringify(header)))
  const payloadPart = base64UrlEncode(textEncoder.encode(JSON.stringify(payload)))
  const signingInput = `${headerPart}.${payloadPart}`

  const signature = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    cryptoKey,
    textEncoder.encode(signingInput),
  )

  const signaturePart = base64UrlEncode(new Uint8Array(signature))
  return `${signingInput}.${signaturePart}`
}

async function sendPush(
  token: string,
  alert: string,
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

function startOfUtcDay(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()))
}

function messageFor(days: number, destination: string): string | null {
  if (days === 14) return `Two weeks until you’re in ${destination}.`
  if (days === 7) return `One week until you’re in ${destination}.`
  if (days === 3) return `Three days until you’re in ${destination}.`
  if (days === 1) return `One day until you’re in ${destination}.`
  if (days === 0) {
    return `Today’s the day — ${destination} is waiting for you. Travel safe ✈️`
  }
  return null
}

type TripRow = {
  id: string | null
  user_id: string | null
  destination: string | null
  check_in: string | null
}

type TokenRow = {
  id: string | null
  token: string | null
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
  const apnsPrivateKey = Deno.env.get('APNS_PRIVATE_KEY')?.replace(/\\n/g, '\n')
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

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const todayUtc = startOfUtcDay(new Date())
  const rangeEnd = new Date(todayUtc)
  rangeEnd.setUTCDate(rangeEnd.getUTCDate() + 15)

  const { data: trips, error: tripsError } = await supabase
    .from('mytrips')
    .select('id, user_id, destination, check_in')
    .gte('check_in', todayUtc.toISOString())
    .lt('check_in', rangeEnd.toISOString())

  if (tripsError) {
    console.error('Trip fetch error', tripsError)
    return new Response('Failed to load trips', { status: 500 })
  }

  const matches: { userId: string; message: string }[] = []
  const dayMs = 24 * 60 * 60 * 1000

  for (const trip of (trips ?? []) as TripRow[]) {
    const userId = trip.user_id ?? ''
    const destination = trip.destination?.trim() ?? ''
    const checkInRaw = trip.check_in ?? ''
    if (!userId || !destination || !checkInRaw) continue

    const checkInDate = new Date(checkInRaw)
    if (Number.isNaN(checkInDate.getTime())) continue

    const checkInUtc = startOfUtcDay(checkInDate)
    const daysOut = Math.round((checkInUtc.getTime() - todayUtc.getTime()) / dayMs)
    const message = messageFor(daysOut, destination)
    if (!message) continue

    matches.push({ userId, message })
  }

  if (matches.length === 0) {
    return new Response(JSON.stringify({ ok: true, sent: 0 }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const userIds = Array.from(new Set(matches.map((match) => match.userId)))

  const { data: tokens, error: tokensError } = await supabase
    .from('device_tokens')
    .select('id, token')
    .in('id', userIds)

  if (tokensError) {
    console.error('Token fetch error', tokensError)
    return new Response('Failed to load tokens', { status: 500 })
  }

  const tokensByUser: Record<string, string[]> = {}
  for (const row of (tokens ?? []) as TokenRow[]) {
    const userId = row.id ?? ''
    const token = row.token ?? ''
    if (!userId || !token) continue
    if (!tokensByUser[userId]) tokensByUser[userId] = []
    tokensByUser[userId].push(token)
  }

  const apnsJwt = await createApnsJwt(apnsTeamId, apnsKeyId, apnsPrivateKey)

  const sends: Promise<void>[] = []
  for (const match of matches) {
    const userTokens = tokensByUser[match.userId] ?? []
    for (const token of userTokens) {
      sends.push(sendPush(token, match.message, apnsHost, apnsBundleId, apnsJwt))
    }
  }

  await Promise.all(sends)

  return new Response(JSON.stringify({ ok: true, sent: sends.length }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
