import { supabase, unwrap, apiError } from './client'

// Accounts live in Supabase Auth. Signing up also creates the customer's
// profiles row (database trigger), using full_name/phone from the metadata.

export async function register({ fullName, email, phone, password }) {
  return unwrap(
    await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName, phone } },
    }),
  )
}

export async function login({ email, password }) {
  return unwrap(await supabase.auth.signInWithPassword({ email, password }))
}

export async function logout() {
  unwrap(await supabase.auth.signOut())
}

export async function fetchMe() {
  const p = unwrap(
    await supabase.from('profiles').select('id, full_name, email, phone').maybeSingle(),
  )
  if (!p) throw apiError('Profile not found', 404)
  return { id: p.id, fullName: p.full_name, email: p.email, phone: p.phone }
}

// The emailed link returns to /reset-password with a short-lived recovery session.
export async function forgotPassword(email) {
  unwrap(
    await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    }),
  )
  return { message: 'If an account exists for that email, a reset link has been sent.' }
}

// Requires the recovery session created by the reset link.
export async function resetPassword(newPassword) {
  unwrap(await supabase.auth.updateUser({ password: newPassword }))
}
