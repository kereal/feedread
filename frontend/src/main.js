import { createApp } from "vue"
import { createWebHistory, createRouter } from "vue-router"
import App from "./App.vue"
import "normalize.css"
import "./style.css"
import RecordList from "./components/RecordList.vue"
import SourceList from "./components/SourceList.vue"

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", name: "records", component: RecordList },
    { path: "/favorites", name: "favorites", component: RecordList },
    { path: "/source/:id", name: "source", component: RecordList },
    { path: "/sources", name: "sources", component: SourceList }
  ]
})

createApp(App).use(router).mount("#app")
