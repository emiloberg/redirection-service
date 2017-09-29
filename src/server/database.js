const url = require("url")
const { Client } = require("pg")
const CONFIG = require("./config")

const params = url.parse(CONFIG.DATABASE_URL)
const auth = params.auth ? params.auth.split(":") : [undefined, undefined]

const client = new Client({
  user: auth[0],
  password: auth[1],
  host: params.hostname,
  port: params.port,
  database: params.pathname.split("/")[1]
  // ssl: true
})

module.exports = () => client.connect().then(() => client)
