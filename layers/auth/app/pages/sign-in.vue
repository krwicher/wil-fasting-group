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
  const { error } = await supabase.auth.signInWithPassword({
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
    await navigateTo("/", { replace: true });
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
