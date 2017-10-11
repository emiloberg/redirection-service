const http = require("http")
const morgan = require("koa-morgan")
const session = require("koa-session")
const bodyParser = require("koa-bodyparser")
const Koa = require("koa")
const passport = require("./authentication")
const router = require("./routes")
const CONFIG = require("./config")

const app = new Koa()
app.keys = [CONFIG.SESSION_SECRET]

app
  .use(session({}, app))
  .use(passport.initialize())
  .use(passport.session())
  .use(async (ctx, next) => {
    if (
      ctx.isAuthenticated() ||
      ctx.url.startsWith(CONFIG.LOGIN_URL) ||
      (ctx.request.method === "GET" && ctx.url === "/rules")
    ) {
      await next()
    } else {
      await ctx.redirect(CONFIG.LOGIN_URL)
    }
  })
  .use(bodyParser())
  .use(morgan("dev"))
  .use(router.routes())
  .use(router.allowedMethods())

http
  .createServer(app.callback())
  .listen(CONFIG.APP_PORT, "0.0.0.0", 511, () => {
    console.log(`Listening on port ${CONFIG.APP_PORT}.`)
  })
