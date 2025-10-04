<template>
  <footer class="border-t-2 border-gray-200">
    <UContainer class="grid grid-cols-2 lg:grid-cols-5 gap-4 py-8">
      <div class="flex flex-col gap-4">
        <h3 class="title title-4">Auta USA</h3>
        <ULink to="/jak-wyglada-import">Jak wygląda import?</ULink>
        <ULink to="/uslugi-i-wsparcie">Usługi i wsparcie</ULink>
        <ULink to="/oddzialy">Oddziały</ULink>
        <ULink to="/pomoc">Pomoc</ULink>
        <ULink to="/o-nas">O nas</ULink>
        <ULink to="/kontakt">Kontakt</ULink>
      </div>
      <div class="flex flex-col gap-4">
        <h3 class="title title-4">Aukcje</h3>
        <ULink to="/aukcje">Aukcje</ULink>
        <ULink to="/nowosci">Nowości</ULink>
        <ULink to="/kalkulator">Kalkulator</ULink>
        <ULink to="/import">Import</ULink>
      </div>
      <div class="flex flex-col gap-4">
        <h3 class="title title-4">Moje konto</h3>
        <ULink to="/sign-in">Zaloguj się</ULink>
        <ULink to="/register">Zarejestruj się</ULink>
        <ULink to="/profile">Depozyty</ULink>
      </div>
      <div class="col-span-2 flex flex-col gap-4">
        <h3 class="title title-4">Dane kontaktowe</h3>
        <p>
          Zadzwoń, napisz lub odwiedź nas – chętnie odpowiemy na każde pytanie.
        </p>
        <p class="flex items-center gap-2">
          <UIcon name="i-lucide-map-pin" class="size-5" />ul. Przykładowa 10,<br />00-000
          Warszawa
        </p>
        <p class="flex items-center gap-2">
          <UIcon name="i-lucide-inbox" class="size-5" />Autausa@poczta.pl
        </p>
        <p class="flex items-center gap-2">
          <UIcon name="i-lucide-phone" class="size-5" />+48 000-000-000
        </p>
        <p>Obserwuj nas na</p>
        <div class="flex items-center gap-2">
          <NuxtImg
            src="/images/icons/facebook.svg"
            alt="Facebook"
            loading="lazy"
            class="h-12"
          />
          <NuxtImg
            src="/images/icons/instagram.svg"
            alt="Instagram"
            loading="lazy"
            class="h-12"
          />
          <NuxtImg
            src="/images/icons/twitter.svg"
            alt="X"
            loading="lazy"
            class="h-12"
          />
        </div>
      </div>
    </UContainer>
    <UContainer
      class="flex flex-col lg:flex-row items-center justify-center gap-4 py-2 lg:gap-8 bg-white"
    >
      <ULink to="/privacy-policy" target="_blank"> Polityka prywatności </ULink>
      <ULink to="/terms-of-service" target="_blank"> Regulamin serwisu </ULink>
      <ULink to="/cookies-policy" target="_blank"> Polityka cookies </ULink>
    </UContainer>
  </footer>
</template>
