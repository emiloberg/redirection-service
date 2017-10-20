const passport = require("koa-passport")
const GoogleStrategy = require("passport-google-oauth20").Strategy
const CONFIG = require("./config")

// We authenticate using OAuth2 via Google.
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

module.exports = passport
