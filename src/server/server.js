const fs = require("fs")
const path = require("path")
const http = require("http")
const passport = require("koa-passport")
const morgan = require("koa-morgan")
const session = require("koa-session")
const GoogleStrategy = require("passport-google-oauth20").Strategy
const { postgraphql } = require("postgraphql")
const bodyParser = require("koa-bodyparser")
const CONFIG = require("./config")
const Koa = require("koa")
const Router = require("koa-router")

const app = new Koa()
const router = new Router()

const indexHtml = fs.readFileSync(path.join(__dirname, "../client/index.html")).toString()
const elmJs = fs.readFileSync(path.join(__dirname, "../../dist/client.js")).toString()
// const mainCss = fs.readFileSync("./src/client/main.css").toString()

const graph = postgraphql(CONFIG.DATABASE_URL, CONFIG.DATABASE_SCHEMA, CONFIG.POSTGRAPHQL_OPTIONS)

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
      // User.findOrCreate({ googleId: profile.id }, function(err, user) {
      //   return done(err, user)
      // })
    }
  )
)

passport.serializeUser(function(user, done) {
  done(null, user.id)
})

passport.deserializeUser(function(id, done) {
  done(null, id)
  // User.findById(id, function(err, user) {
  //   done(err, user)
  // })
})

router.get("/client.js", async ctx => {
  ctx.body = elmJs
})

// router.get("/main.css", (req, res) => {
//   res.setHeader("content-type", "text/css")
//   res.writeHead(200)
//   res.end(mainCss)
// })

router.get("/login", passport.authenticate("google", { scope: ["profile", "email"] }))

router.get(
  "/login/callback",
  passport.authenticate("google", {
    failureRedirect: "/login",
    scope: ["profile", "email"]
  }),
  async ctx => {
    console.log("aSDFASDF")
    // Successful authentication, redirect home.
    ctx.redirect("/")
  }
)

router.get("/", async ctx => {
  ctx.body = indexHtml
})

app.use(session({}, app))
app.keys = [CONFIG.SESSION_SECRET]

app
  .use(passport.initialize())
  .use(passport.session())
  .use(morgan("dev"))
  .use(graph)
  .use(router.routes())
  .use(router.allowedMethods())

http.createServer(app.callback()).listen(CONFIG.APP_PORT, "0.0.0.0", 511, event => {
  console.log(`Listening on port ${CONFIG.APP_PORT}.`)
})
