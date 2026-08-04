<template>
  <div class="app-brand-logo" :class="{ 'app-brand-logo--compact': compact }">
    <img :src="brandLogoUrl" class="app-brand-logo__img" :alt="brandName" />
  </div>
</template>

<script>
import { BRAND_LOGO_URL, BRAND_NAME } from '@/const/brand';

export default {
  name: 'AppBrandLogo',
  props: {
    compact: {
      type: Boolean,
      default: false
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

<style lang="less" scoped>
.app-brand-logo {
  display: flex;
  align-items: center;
  width: 160px;
  height: 49px;
  flex: 0 1 160px;
  min-width: 0;

  &__img {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: contain;
    object-position: left center;
  }

  &--compact {
    width: 92px;
    height: 28px;
    flex-basis: 92px;
  }
}
</style>
