const fs = require("fs")
const path = require("path")
const Router = require("koa-router")
const passport = require("koa-passport")
const db = require("./database")
const CONFIG = require("./config")

const router = new Router()

// static assets
const indexHtml = fs
  .readFileSync(path.join(__dirname, "../client/index.html"))
  .toString()
const elmJs = fs
  .readFileSync(path.join(__dirname, "../../dist/client.js"))
  .toString()
const logoSvg = fs.readFileSync(path.join(__dirname, "./logo.svg")).toString()

// Route helpers
const handleValidationError = (ctx, error) => {
  if (
    error.name == "SequelizeValidationError" ||
    error.name == "SequelizeUniqueConstraintError"
  ) {
    ctx.status = 422
    ctx.body = error.errors[0].message
  } else {
    throw error
  }
}

// Authentication routes
router.get(
  CONFIG.LOGIN_URL,
  passport.authenticate("google", { scope: ["profile", "email"] })
)

router.get(
  CONFIG.LOGIN_CALLBACK_URL,
  passport.authenticate("google", {
    failureRedirect: CONFIG.LOGIN_URL,
    scope: ["profile", "email"]
  }),
  async ctx => ctx.redirect("/")
)

router.get("/logout", async ctx => {
  ctx.logout()
  ctx.redirect("/")
})

// Asset routes
router.get("/", async ctx => {
  ctx.body = indexHtml
})

router.get("/client.js", async ctx => {
  ctx.body = elmJs
})

router.get("/logo.svg", async ctx => {
  ctx.body = logoSvg
  ctx.type = "image/svg+xml"
})

// rule routes
router.put("/rules/:id", async ctx => {
  try {
    ctx.body = await db.updateRule(
      ctx.params.id,
      ctx.request.body,
      ctx.state.user.emails[0].value
    )
  } catch (e) {
    handleValidationError(ctx, e)
  }
})

router.get("/rules", async ctx => {
  ctx.body = await db.getAllRules()
})

router.post("/rules", async ctx => {
  try {
    ctx.body = await db.createRule(
      ctx.request.body,
      ctx.state.user.emails[0].value
    )
  } catch (e) {
    handleValidationError(ctx, e)
  }
})

router.delete("/rules/:id", async ctx => {
  await db.deleteRule(ctx.params.id)
  ctx.status = 204
})

module.exports = router
