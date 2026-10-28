import { createClient } from '@supabase/supabase-js'

// The site talks to Supabase directly — there is no backend server. The
// publishable key is safe to ship in the bundle: what it can read or write is
// decided by the Row Level Security rules in site/supabase/migrations/.
const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!url || !key) {
  throw new Error('Missing VITE_SUPABASE_URL / VITE_SUPABASE_PUBLISHABLE_KEY (see .env.example)')
}

export const supabase = createClient(url, key)

// Views read failures as `e.response.data.message` / `e.response.status` — the
// shape the old Spring Boot API produced through axios — so every Supabase
// error is rethrown in that shape and the views need no changes.
export function apiError(message, status = 400) {
  const err = new Error(message)
  err.response = { status, data: { message } }
  return err
}

/** Return `data` from a Supabase result, or throw it as an apiError. */
export function unwrap({ data, error, status }) {
  if (!error) return data
  const code = error.status ?? status
  // No HTTP status means the request never reached Supabase (offline, DNS, …).
  if (!code) throw apiError('Network problem — please check your connection and try again.', 0)
  throw apiError(error.message, code)
}
