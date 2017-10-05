const http = require("http")
const passport = require("koa-passport")
const morgan = require("koa-morgan")
const session = require("koa-session")
const GoogleStrategy = require("passport-google-oauth20").Strategy
const bodyParser = require("koa-bodyparser")
const CONFIG = require("./config")
const Koa = require("koa")

const router = require("./routes")
const app = new Koa()
app.keys = [CONFIG.SESSION_SECRET]

passport.use(
  new GoogleStrategy(
    {
      clientID: CONFIG.GOOGLE_CLIENT_ID,
      clientSecret: CONFIG.GOOGLE_CLIENT_SECRET,
      callbackURL: CONFIG.GOOGLE_REDIRECT_URI
    },
    (accessToken, refreshToken, profile, done) => {
      if (!profile.emails.some(email => email.value.endsWith("izettle.com"))) {
        done(new Error("Not the correct domain."))
        return
      }

      done(null, profile)
    }
  )
)

passport.serializeUser((user, done) => {
  done(null, user)
})

passport.deserializeUser((profile, done) => done(null, profile))

app
  .use(session({}, app))
  .use(passport.initialize())
  .use(passport.session())
  .use(async (ctx, next) => {
    if (ctx.isAuthenticated() || ctx.url.startsWith(CONFIG.LOGIN_URL)) {
      await next()
    } else {
      await ctx.redirect(CONFIG.LOGIN_URL)
    }
  })
  .use(bodyParser())
  .use(morgan("dev"))
  .use(router.routes())
  .use(router.allowedMethods())

http.createServer(app.callback()).listen(CONFIG.APP_PORT, "0.0.0.0", 511, event => {
  console.log(`Listening on port ${CONFIG.APP_PORT}.`)
})
