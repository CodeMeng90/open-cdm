<template>
  <CustomIcon v-if="icon" class="loading-icon" :type="icon" :size="size" rightMargin />
  <img v-else class="loading-icon loading-brand-logo" :src="brandLogoUrl" :alt="brandName" :style="{ width: size }" />
</template>

<script>
import { BRAND_LOGO_URL, BRAND_NAME } from '@/const/brand';

export default {
  props: {
    icon: {
      type: String,
      default: ''
    },
    size: {
      type: String,
      default: '80px'
    }
  },
  data() {
    return {
      brandLogoUrl: BRAND_LOGO_URL,
      brandName: BRAND_NAME
    };
  }
};
</script>

<style scoped>
.loading {
  background-color: transparent;
}

.loading-icon {
  animation: blurFade 2.5s ease-in-out infinite;
}

.loading-brand-logo {
  display: block;
  height: auto;
  margin-right: 5px;
  object-fit: contain;
}

@keyframes blurFade {
  0% {
    opacity: 0.4;
    filter: blur(2px);
    transform: scale(0.95);
  }
  50% {
    opacity: 1;
    filter: blur(0);
    transform: scale(1);
  }
  100% {
    opacity: 0.4;
    filter: blur(2px);
    transform: scale(0.95);
  }
}
</style>
