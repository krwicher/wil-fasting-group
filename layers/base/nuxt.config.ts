// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: true },
  modules: ["@nuxt/ui", "@nuxtjs/supabase"],
  css: ["./layers/base/app/assets/css/main.css"],
  supabase: {
    redirectOptions: {
      login: "/sign-in",
      callback: "/auth/callback",
      exclude: [
        "/sign-in",
        "/sign-up",
        "/",
        "/auth/callback",
        "/auth/complete-profile",
        "/auth/pending",
      ],
    },
  },
  runtimeConfig: {
    public: {
      supabaseUrl: process.env.SUPABASE_URL,
      supabaseKey: process.env.SUPABASE_KEY,
    },
  },
});
