<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { submitContact } from '@/api/content'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const route = useRoute()
const form = reactive({ name: '', email: '', phone: '', message: '' })

onMounted(() => {
  // Pre-fill when arriving via an order "Follow Up" link.
  if (route.query.ref) form.message = `Following up on my order ${route.query.ref}: `
})
const status = ref('idle') // idle | sending | sent | error
const errorMsg = ref('')

async function submit() {
  status.value = 'sending'
  errorMsg.value = ''
  try {
    await submitContact({ ...form })
    status.value = 'sent'
    form.name = form.email = form.phone = form.message = ''
  } catch (e) {
    status.value = 'error'
    errorMsg.value = e?.response?.data?.message || 'Something went wrong. Please try again.'
  }
}
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl grid md:grid-cols-2 gap-xl">
    <div>
      <h1 class="font-headline-md text-headline-md mb-md">Get in touch</h1>
      <p class="text-on-surface-variant font-body-lg mb-lg">
        Questions about our products, bulk orders, or partnering with us? Send a message and our team
        will get back to you.
      </p>
      <ul class="flex flex-col gap-md">
        <li class="flex items-center gap-sm text-on-surface-variant">
          <span class="w-10 h-10 shrink-0 rounded-full bg-primary/10 text-primary flex items-center justify-center"><MaterialIcon name="location_on" /></span>
          Embu County, Kenya
        </li>
        <li class="flex items-center gap-sm text-on-surface-variant">
          <span class="w-10 h-10 shrink-0 rounded-full bg-primary/10 text-primary flex items-center justify-center"><MaterialIcon name="mail" /></span>
          <!-- One unbreakable 25-char token; without break-all it sets the
               column's min-width and pushes the page wide on small phones. -->
          <span class="min-w-0 break-all">hello@360econovations.com</span>
        </li>
      </ul>
    </div>

    <div class="bg-surface-container-lowest rounded-xl p-md sm:p-lg shadow-low">
      <div v-if="status === 'sent'" class="flex flex-col items-center text-center py-lg">
        <span class="w-16 h-16 rounded-full bg-primary/10 text-primary flex items-center justify-center mb-md"><MaterialIcon name="check_circle" filled /></span>
        <h3 class="font-headline-sm text-headline-sm mb-xs">Message sent</h3>
        <p class="text-on-surface-variant">Thanks — we'll be in touch soon.</p>
        <button class="mt-md text-primary font-label-sm" @click="status = 'idle'">Send another</button>
      </div>

      <form v-else class="flex flex-col gap-md" @submit.prevent="submit">
        <label class="flex flex-col gap-xs">
          <span class="font-label-sm text-label-sm text-on-surface-variant">Name</span>
          <input v-model="form.name" required class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        </label>
        <label class="flex flex-col gap-xs">
          <span class="font-label-sm text-label-sm text-on-surface-variant">Email</span>
          <input v-model="form.email" type="email" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        </label>
        <label class="flex flex-col gap-xs">
          <span class="font-label-sm text-label-sm text-on-surface-variant">Phone</span>
          <input v-model="form.phone" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        </label>
        <label class="flex flex-col gap-xs">
          <span class="font-label-sm text-label-sm text-on-surface-variant">Message</span>
          <textarea v-model="form.message" required rows="4" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary"></textarea>
        </label>
        <p v-if="status === 'error'" class="text-error font-body-md">{{ errorMsg }}</p>
        <button
          type="submit"
          :disabled="status === 'sending'"
          class="bg-primary text-on-primary font-label-sm text-label-sm py-3 rounded-full hover:bg-primary-container transition-colors disabled:opacity-50"
        >
          {{ status === 'sending' ? 'Sending…' : 'Send Message' }}
        </button>
      </form>
    </div>
  </section>
</template>
