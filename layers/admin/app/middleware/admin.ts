export default defineNuxtRouteMiddleware((to, from) => {
  const { isAdmin } = useUserRole();

  if (!isAdmin.value) {
    return navigateTo("/");
  }
});
