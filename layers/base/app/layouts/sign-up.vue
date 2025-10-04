<script setup lang="ts">
const user = useSupabaseUser();
console.log(user.value);
</script>

<template>
  <div class="layout-container flex flex-col min-h-screen">
    <AppHeader />
    <main class="flex-1 flex items-center justify-center">
      <slot />
    </main>
  </div>
</template>
