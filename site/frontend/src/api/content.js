import { supabase, unwrap, apiError } from './client'

export async function fetchContent(pageSlug, sectionKey) {
  const row = unwrap(
    await supabase
      .from('page_content')
      .select('content')
      .eq('page_slug', pageSlug)
      .eq('section_key', sectionKey)
      .maybeSingle(),
  )
  if (!row) throw apiError(`Content not found: ${pageSlug}/${sectionKey}`, 404)
  return row.content
}

// Server-side function: combines curated figures with live supply-chain totals.
export async function fetchImpact() {
  return unwrap(await supabase.rpc('get_impact'))
}

// Insert-only: the site may send messages but never read them back.
export async function submitContact({ name, email, phone, message }) {
  unwrap(
    await supabase.from('contact_submissions').insert({
      name: name.trim(),
      email: email?.trim() || null,
      phone: phone?.trim() || null,
      message,
    }),
  )
  return { message: "Thanks — we'll be in touch." }
}
