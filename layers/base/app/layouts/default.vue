<script setup lang="ts">
const user = useSupabaseUser();
console.log(user.value);
</script>

<template>
  <div class="layout-container min-h-screen">
    <AppHeader />
    <main>
      <slot />
    </main>
    <AppFooter />
  </div>
</template>
