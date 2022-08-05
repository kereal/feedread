<template>
  <p class="error" v-if="error">
    {{ error }}
    <a class="i16 reload" title="Загрузить записи" @click.prevent="loadRecords()"></a>
  </p>

  <div class="records" v-if="!empty">
    <transition-group name="record">
      <div
        v-for="(record, idx) in records"
        :key="record.id"
        class="record"
        :class="{ selected: idx === selected_idx }"
      >
        <div class="actions">
          <a @click.prevent="deleteRecord(record.id)" class="i16 trash"></a><br />
          <a
            @click.prevent="favoriteRecord(record.id)"
            class="i16 bookmark"
            v-if="$route.name !== 'favorites'"
          ></a>
        </div>
        <div class="title">
          <router-link
            class="source"
            :to="{ name: 'source', params: { id: record.source_id } }"
            >{{ record.source_title }}</router-link
          >
          <a :href="record.link" class="link" target="_blank">{{ record.title }}</a>
        </div>
        <div class="category" v-if="record.category">
          {{ record.category }}
          <a
            @click.prevent="banCategory(record.source_id, record.category)"
            class="ban"
            title="Забанить категорию"
          >
            <span class="i16 ban"></span>
          </a>
        </div>
        <span class="pubdate" v-if="record.pubdate">
          {{ formatPubdate(record.pubdate) }}
        </span>
        <div class="content" v-if="record.content" v-html="record.content"></div>
      </div>
    </transition-group>
  </div>

  <a
    class="load-more"
    title="Следующие"
    v-if="!empty"
    @click.prevent="loadRecords(records.length + offset)"
    ><span>{{ offset === 0 ? "" : `${offset}&hellip;` }}</span
    ><i>&rarr;</i></a
  >

  <p class="empty" v-if="not_found && !error">
    Пока все
    <a class="i16 reload" title="Загрузить записи" @click.prevent="loadRecords()"></a>
  </p>
</template>

<script>
import axiosInstance from "../axiosInstance"

function isInViewport(el) {
  const rect = el.getBoundingClientRect()
  return (
    rect.top >= rect.top * 1.5 &&
    rect.left >= 0 &&
    rect.bottom * 2 <= (window.innerHeight || document.documentElement.clientHeight) &&
    rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  )
}

export default {
  data: () => ({
    error: null,
    not_found: false,
    selected_idx: 0,
    offset: 0,
    records: []
  }),
  watch: {
    empty: function (value) {
      if (value && !this.not_found) this.loadRecords()
    }
  },
  methods: {
    keyboardEvent(e) {
      //console.log(e)
      if (e.which === 40 && this.selected_idx + 1 < this.records.length) {
        this.selected_idx++
        e.preventDefault()
        const sel = document.querySelector(".record.selected")
        if (!isInViewport(sel)) sel.scrollIntoView({ behavior: "smooth" })
      }
      if (e.which === 38 && this.selected_idx != 0) {
        this.selected_idx--
        e.preventDefault()
        const sel = document.querySelector(".record.selected")
        if (!isInViewport(sel)) sel.scrollIntoView({ behavior: "smooth", block: "end" })
      }
      if (e.which === 46) {
        this.deleteRecord(this.records[this.selected_idx].id)
      }
      if (e.which === 66)
        this.banCategory(
          this.records[this.selected_idx].source_id,
          this.records[this.selected_idx].category
        )
      if (e.which === 221)
        document.querySelector(".record.selected > .title > a.link").focus()
    },
    formatPubdate(pubdate) {
      const d = new Date(pubdate)
      return (d.toLocaleDateString() + ", " + d.toLocaleTimeString()).slice(0, -3)
    },
    async loadRecords(offset = 0) {
      this.$emit("loading", true)
      this.error = null
      this.not_found = false
      try {
        const { data } = await axiosInstance.get(
          `/records${
            this.$route.path === "/" ? "" : this.$route.path
          }?limit=10&offset=${offset}`
        )
        this.records = data
        this.offset = offset
        if (!this.empty) this.selected_idx = 0
        else this.not_found = true
      } catch (e) {
        console.log(e), (this.error = e.message)
      }
      this.$emit("loading", false)
    },
    async deleteRecord(id) {
      if (!id) return
      this.$emit("loading", true)
      this.error = null
      try {
        const { data } = await axiosInstance.delete(`/records/${id}`)
        this.records = this.records.filter((record) => record.id !== parseInt(data.id))
        if (!this.records[this.selected_idx]) this.selected_idx--
      } catch (e) {
        console.log(e), (this.error = e.message)
      }
      this.$emit("loading", false)
    },
    async banCategory(source_id, title) {
      this.$emit("loading", true)
      try {
        await axiosInstance.post(`sources/${source_id}/ignore_category`, {
          category: title
        })
      } catch (e) {
        console.log(e), (this.error = e.message)
      }
      this.loadRecords()
      this.$emit("loading", false)
    },
    async favoriteRecord(id) {
      this.$emit("loading", true)
      try {
        const { data } = await axiosInstance.post(`/records/${id}/favorite`)
        this.records = this.records.filter((record) => record.id !== parseInt(data.id))
      } catch (e) {
        console.log(e), (this.error = e.message)
      }
      this.$emit("loading", false)
    }
  },
  computed: {
    empty: function () {
      return !this.records.length
    }
  },
  beforeRouteLeave(from, to, next) {
    window.removeEventListener("keydown", this.keyboardEvent)
    next()
  },
  mounted() {
    this.loadRecords()
    window.addEventListener("keydown", this.keyboardEvent)
  },
  emits: ["loading"]
}
</script>
