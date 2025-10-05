<script setup lang="ts">
const user = useSupabaseUser();
console.log(user.value);
</script>

<template>
  <div class="layout-container flex flex-col min-h-screen max-h-screen">
    <AppHeader />
    <main
      class="flex-1 flex items-stretch justify-center max-h-[calc(100vh-169px)]"
    >
      <slot />
    </main>
  </div>
</template>
