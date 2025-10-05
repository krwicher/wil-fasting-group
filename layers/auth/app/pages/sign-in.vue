<script setup lang="ts">
import z from "zod";

definePageMeta({
  layout: "sign-up",
});
const supabase = useSupabaseClient();
const toast = useToast();

const fields = [
  {
    name: "email",
    type: "text" as const,
    label: "Email",
    placeholder: "Wpisz adres e-mail",
    required: true,
    size: "xl",
  },
  {
    name: "password",
    label: "Hasło",
    type: "password" as const,
    placeholder: "Wpisz hasło",
    required: true,
    size: "xl",
  },
];

async function handleSubmit(payload: any) {
  const email = payload.data.email;
  const password = payload.data.password;
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  if (error) displayError(error);
  else {
    toast.add({
      title: "Zalogowano pomyślnie",
      icon: "i-lucide-check-circle",
      color: "success",
    });

    // Check if user needs to complete their profile
    const needsProfileCompletion = !data.user?.user_metadata?.display_name;

    if (needsProfileCompletion) {
      await navigateTo("/auth/complete-profile", { replace: true });
    } else {
      // The approval middleware will redirect to pending if needed
      await navigateTo("/", { replace: true });
    }
  }
}

const displayError = (error: any) => {
  toast.add({
    title: "Error",
    description: error.message,
    icon: "i-lucide-alert-circle",
    color: "error",
  });
};

const oauthLoading = ref(false);

async function signInWithGoogle() {
  oauthLoading.value = true;
  const { error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: `${window.location.origin}/auth/callback`,
    },
  });
  if (error) {
    displayError(error);
    oauthLoading.value = false;
  }
}

async function signInWithApple() {
  oauthLoading.value = true;
  const { error } = await supabase.auth.signInWithOAuth({
    provider: "apple",
    options: {
      redirectTo: `${window.location.origin}/auth/callback`,
    },
  });
  if (error) {
    displayError(error);
    oauthLoading.value = false;
  }
}

const schema = z.object({
  email: z.string().email("Niepoprawny adres e-mail"),
  password: z.string().min(8, "Hasło musi mieć co najmniej 8 znaków"),
});
</script>
<template>
  <div class="grid lg:grid-cols-2 w-full">
    <div class="flex items-center justify-center">
      <UAuthForm
        title="Zarejestruj się"
        :schema="schema"
        :fields="fields"
        @submit="handleSubmit"
        :submit="{
          label: 'Zaloguj się',
          size: 'xl',
        }"
        class="max-w-[28rem] margin-auto"
        :ui="{
          title: 'text-3xl text-left',
          description: 'text-left',
        }"
      >
        <template #description>
          Wprowadź swój adres e-mail i hasło, aby uzyskać dostęp do swojego
          konta.
        </template>

        <template #footer>
          <div class="mt-6 space-y-3">
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-300"></div>
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-white text-gray-500">Or continue with</span>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <UButton
                color="neutral"
                variant="outline"
                size="lg"
                :loading="oauthLoading"
                @click="signInWithGoogle"
                block
              >
                <template #leading>
                  <UIcon name="i-logos-google-icon" class="w-5 h-5" />
                </template>
                Google
              </UButton>

              <UButton
                color="neutral"
                variant="outline"
                size="lg"
                :loading="oauthLoading"
                @click="signInWithApple"
                block
              >
                <template #leading>
                  <UIcon name="i-logos-apple" class="w-5 h-5" />
                </template>
                Apple
              </UButton>
            </div>
          </div>
        </template>
      </UAuthForm>
    </div>
    <div class="sign-up-image hidden lg:block">
      <NuxtImg
        src="/images/sign-up.jpg"
        alt="Sign up"
        class="object-cover max-h-[calc(100vh-169px)] w-full"
      />
    </div>
  </div>
</template>
