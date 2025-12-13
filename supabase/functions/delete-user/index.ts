import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceRoleKey) {
    console.error('Missing env config')
    return new Response('Server not configured', { status: 500 })
  }

  const authHeader = req.headers.get('Authorization') ?? ''
  const token = authHeader.replace('Bearer', '').trim()
  if (!token) {
    return new Response('Missing access token', { status: 401 })
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const { data: userData, error: userError } = await
adminClient.auth.getUser(token)
  if (userError || !userData?.user) {
    console.error('Invalid token', userError)
    return new Response('Invalid token', { status: 401 })
  }

  const userId = userData.user.id
  const { error: authDeleteError } = await
adminClient.auth.admin.deleteUser(userId)
  if (authDeleteError) {
    console.error('Failed to delete auth user', authDeleteError)
    return new Response('Failed to delete auth user', { status: 500 })
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
