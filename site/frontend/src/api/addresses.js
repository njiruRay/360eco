import { supabase, unwrap, apiError } from './client'

// RLS scopes every query to the signed-in customer; user_id is filled in by
// the database, and setting is_default clears the customer's other defaults.

function toAddress(a) {
  return {
    id: a.id,
    label: a.label,
    subCounty: a.sub_county,
    town: a.town,
    street: a.street,
    isDefault: a.is_default,
  }
}

function toRow(payload) {
  return {
    label: payload.label ?? null,
    sub_county: payload.subCounty,
    town: payload.town ?? null,
    street: payload.street ?? null,
    is_default: !!payload.isDefault,
  }
}

export async function fetchAddresses() {
  const rows = unwrap(
    await supabase
      .from('addresses')
      .select('*')
      .order('is_default', { ascending: false })
      .order('id'),
  )
  return rows.map(toAddress)
}

export async function createAddress(payload) {
  return toAddress(
    unwrap(await supabase.from('addresses').insert(toRow(payload)).select().single()),
  )
}

export async function updateAddress(id, payload) {
  const row = unwrap(
    await supabase.from('addresses').update(toRow(payload)).eq('id', id).select().maybeSingle(),
  )
  if (!row) throw apiError('Address not found', 404)
  return toAddress(row)
}

export async function deleteAddress(id) {
  unwrap(await supabase.from('addresses').delete().eq('id', id))
}
