const fs = require("fs")
const path = require("path")
const http = require("http")
const passport = require("koa-passport")
const morgan = require("koa-morgan")
const session = require("koa-session")
const GoogleStrategy = require("passport-google-oauth20").Strategy
const bodyParser = require("koa-bodyparser")
const CONFIG = require("./config")
const Koa = require("koa")
const Router = require("koa-router")

const app = new Koa()
const router = new Router()

const indexHtml = fs.readFileSync(path.join(__dirname, "../client/index.html")).toString()
const elmJs = fs.readFileSync(path.join(__dirname, "../../dist/client.js")).toString()
// const mainCss = fs.readFileSync("./src/client/main.css").toString()

const LOGIN_URL = "/login"
const LOGIN_CALLBACK_URL = "/login/callback"

const db = require("./database")

passport.use(
  new GoogleStrategy(
    {
      clientID: CONFIG.GOOGLE_CLIENT_ID,
      clientSecret: CONFIG.GOOGLE_CLIENT_SECRET,
      callbackURL: CONFIG.GOOGLE_REDIRECT_URI
    },
    function(accessToken, refreshToken, profile, done) {
      if (!profile.emails.some(email => email.value.endsWith("izettle.com"))) {
        done(new Error("Not the correct domain."))
        return
      }

      done(null, profile)
    }
  )
)

passport.serializeUser(function(user, done) {
  done(null, user)
})

passport.deserializeUser((profile, done) => done(null, profile))

router.get("/client.js", async ctx => {
  ctx.body = elmJs
})

// router.get("/main.css", (req, res) => {
//   res.setHeader("content-type", "text/css")
//   res.writeHead(200)
//   res.end(mainCss)
// })

router.get(LOGIN_URL, passport.authenticate("google", { scope: ["profile", "email"] }))

router.get(
  LOGIN_CALLBACK_URL,
  passport.authenticate("google", {
    failureRedirect: LOGIN_URL,
    scope: ["profile", "email"]
  }),
  async ctx => ctx.redirect("/")
)

router.get("/", async ctx => {
  ctx.body = indexHtml
})

router.get("/rules", async ctx => {
  ctx.body = await db.getAllRules()
})

router.post("/rules", async ctx => {
  ctx.body = await db.createRule(ctx.request.body, ctx.state.user.emails[0].value)
})

app.use(session({}, app))
app.keys = [CONFIG.SESSION_SECRET]

app
  .use(passport.initialize())
  .use(passport.session())

app.use(async (ctx, next) => {
  if (ctx.isAuthenticated() || ctx.url.startsWith(LOGIN_URL)) {
    await next()
  } else {
    await ctx.redirect(LOGIN_URL)
  }
})

app
  .use(bodyParser())
  .use(morgan("dev"))
  .use(router.routes())
  .use(router.allowedMethods())

http.createServer(app.callback()).listen(CONFIG.APP_PORT, "0.0.0.0", 511, event => {
  console.log(`Listening on port ${CONFIG.APP_PORT}.`)
})
