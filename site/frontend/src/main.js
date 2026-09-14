import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import router from './router'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')

// Dismiss the Eco Message splash (see index.html) once the router has resolved
// the first route — routes are lazy-loaded, so mounting alone still leaves the
// page blank. The splash self-dismisses on window load / after 7s regardless.
router.isReady().then(() => {
  window.__ecoLoaderDone?.()
})
