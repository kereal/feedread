import axios from "axios"

export default axios.create({
  baseURL: import.meta.env.PROD
    ? import.meta.env.VITE_PROD_API_URL
    : "http://127.0.0.1:3000/",
  //: "http://192.168.0.200:3000/",
  headers: {
    "Content-Type": "multipart/form-data"
    // Authorization: `Bearer ${process.env.VUE_APP_KEY}`,
    // apikey: `${process.env.VUE_APP_KEY}`,
  }
})
