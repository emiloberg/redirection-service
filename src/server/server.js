const fs = require("fs")
const path = require("path")
const http = require("http")
// const { postgraphql } = require("postgraphql")
// const auth = require("http-auth")
// const CONFIG = require("./config")

const indexHtml = fs.readFileSync(path.join(__dirname, "../client/index.html")).toString()
const elmJs = fs.readFileSync(path.join(__dirname, "../../dist/client.js")).toString()
// const mainCss = fs.readFileSync("./src/client/main.css").toString()
// const graph = postgraphql(CONFIG.DATABASE_URL, CONFIG.DATABASE_NAME, CONFIG.POSTGRAPHQL_OPTIONS)

// const basic = auth.basic(
//   {
//     realm: "iZettle Support Devices"
//   },
//   (username, password, callback) => {
//     callback(username === "wwwtest" && password === "qwer1234")
//   }
// )

http
  .createServer(
    /*basic,*/ (req, res) => {
      switch (req.url) {
        case "/":
          res.writeHead(200)
          res.end(indexHtml)
          break

        case "/client.js":
          res.writeHead(200)
          res.end(elmJs)
          break

        // case "/main.css":
        //   res.setHeader("content-type", "text/css")
        //   res.writeHead(200)
        //   res.end(mainCss)
        //   break

        default:
          res.writeHead(404)
          res.end()
        // graph(req, res)
      }
    }
  )
  .listen(3000, "0.0.0.0", 511, event => {
    console.log("Listening on port 3000.")
  })
