<template>
  <nav id="nav">
    <ul>
      <li>
        <router-link :to="{ name: 'records' }">
          <span class="i16 home"></span> все
        </router-link>
      </li>
      <li>
        <router-link :to="{ name: 'favorites' }">
          <span class="i16 bookmark"></span> избранное
        </router-link>
      </li>
      <li>
        <router-link :to="{ name: 'sources' }">
          <span class="i16 folder"></span> источники
        </router-link>
      </li>
      <li class="right">
        <a href="#" @click.prevent="toggleTheme" title="Переключить тему">
          <span class="i16 sun" :class="{ spin: loading }"></span>
        </a>
      </li>
    </ul>
  </nav>

  <router-view :key="$route.path" @loading="loadingHandler"></router-view>
</template>

<script>
export default {
  data: () => ({
    loading: false
  }),
  methods: {
    loadingHandler(value) {
      this.loading = value
    },
    toggleTheme() {
      const list = document.querySelector("body").classList
      if (list.contains("dark")) {
        list.remove("dark")
        localStorage.removeItem("isDarkMode")
      } else {
        list.add("dark")
        localStorage.setItem("isDarkMode", true)
      }
    }
  },
  mounted() {
    if (localStorage.getItem("isDarkMode")) {
      document.querySelector("body").classList.add("dark")
    }
  }
}
</script>
