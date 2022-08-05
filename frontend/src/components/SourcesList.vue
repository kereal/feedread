<template>
  <div class="sources" v-if="sources.length">
    <div class="source" v-for="source in sources" :key="source.id">
      <span class="id">{{ source.id }}</span>
      <span class="type">{{ source.type }} </span>
      <span class="title">
        <router-link :to="{ name: 'source', params: { id: source.id } }">
          {{ source.title }}
        </router-link>
      </span>
      <span class="active">{{ !!source.active ? "Активен" : "Не активен" }}</span>
      <span class="last_parsed">{{ dateTime(source.last_parsed_at) }}</span>
      <span class="actions">
        <a href="#" @click.prevent="showForm(source)" class="i16 edit"></a>&nbsp;
        <a href="#" @click.prevent="deleteSource(source.id)" class="i16 trash"></a>
      </span>
    </div>
  </div>

  <p class="error" v-if="error">
    {{ error }}
    <a class="i16 reload" title="Загрузить источники" @click.prevent="loadSources()"></a>
  </p>
  <div class="empty" v-else-if="!sources.length">
    <p>Источники не найдены</p>
  </div>
  <a href="#" @click.prevent="showForm" v-else><span class="i16 plus"></span> Создать</a>

  <div class="modal" v-if="modalVisible" @keydown.esc="modalVisible = false">
    <form @submit.prevent="saveSource">
      <div class="title">Тип</div>
      <select id="type" ref="formi" v-model="source.type" required>
        <option value="rss">rss</option>
        <option value="atom">atom</option>
      </select>
      <div class="title">Название</div>
      <input type="text" name="title" v-model.trim="source.title" required />
      <div class="title">URL</div>
      <input type="text" name="url" v-model.trim="source.url" required />
      <div class="title">Активен</div>
      <select v-model="source.active" required>
        <option value="true">Да</option>
        <option value="false">Нет</option>
      </select>
      <button>Сохранить</button>
      <button @click.prevent="modalVisible = false">Закрыть</button>
    </form>
  </div>
</template>

<script>
import axiosInstance from "../axiosInstance"

export default {
  data: () => ({
    modalVisible: false,
    error: null,
    sources: [],
    source: {}
  }),
  methods: {
    showForm(source) {
      this.modalVisible = true
      this.source = Object.assign({}, source)
      this.$nextTick(() => {
        this.$refs["formi"].focus()
      })
    },
    async saveSource() {
      this.modalVisible = false
      const word = "sources" + (this.source.id ? `/${this.source.id}` : "/")
      try {
        await axiosInstance.post(word, {
          type: this.source.type,
          title: this.source.title,
          url: this.source.url,
          active: this.source.active
        })
      } catch (e) {
        console.log(e)
      }
      this.loadSources()
    },
    dateTime(d) {
      const date = new Date(d)
      return d ? date.toLocaleDateString() + ", " + date.toLocaleTimeString() : null
    },
    async loadSources() {
      this.$emit("loading", true)
      try {
        const { data } = await axiosInstance.get("sources")
        this.sources = data
      } catch (e) {
        console.log(e), (this.error = e.message)
      }
      this.$emit("loading", false)
    },
    async deleteSource(id) {
      if (!id || !confirm("Точно удалить вместе с записями этого источника?")) return
      this.$emit("loading", true)
      try {
        const { data } = await axiosInstance.delete(`sources/${id}`)
        this.sources = this.sources.filter((source) => source.id !== parseInt(data.id))
      } catch (e) {
        console.log(e)
      }
      this.$emit("loading", false)
    }
  },
  created() {
    this.loadSources()
  },
  emits: ["loading"]
}
</script>

<style>
span.i16.plus {
  position: relative;
  top: 2px;
}
</style>
