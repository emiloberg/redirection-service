module.exports = {
  DATABASE_URL:
    process.env.DATABASE_URL || "postgres://localhost:5432/redirection_service",
  DATABASE_NAME: process.env.DATABASE_NAME || "redirection_service",
  DATABASE_SCHEMA: process.env.DATABASE_SCHEMA || "public",
  APP_PORT: process.env.PORT || 3001,
  LOGIN_URL: process.env.LOGIN_URL || "/login",
  LOGIN_CALLBACK_URL: process.env.LOGIN_CALLBACK_URL || "/login/callback",
  GOOGLE_REDIRECT_URI:
    process.env.GOOGLE_REDIRECT_URI ||
    "http://redirection-service.izettle-dev.com:3001/login/callback",
  GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID,
  GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET,
  SESSION_SECRET: process.env.SESSION_SECRET || "keyboard cat"
}
