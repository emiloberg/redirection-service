const Sequelize = require("sequelize")
const CONFIG = require("./config")

const sequelize = new Sequelize(CONFIG.DATABASE_URL)

const Rule = sequelize.define("rule", {
  id: { type: Sequelize.INTEGER, primaryKey: true },
  from: { type: Sequelize.STRING },
  to: { type: Sequelize.STRING },
  kind: { type: Sequelize.STRING },
  why: { type: Sequelize.STRING },
  who: { type: Sequelize.STRING },
  isRegex: { type: Sequelize.BOOLEAN, field: "is_regex" }
}, {
  createdAt: "created",
  updatedAt: "updated"
});

async function getAllRules() {
  return await Rule.findAll()
}

async function createRule(rule, user) {
  // TODO - Validation
  return await Rule.create({
    ...rule,
    who: user
  }, { fields: ["from", "to", "kind", "why", "who", "isRegex" ]})
}

module.exports = {
  getAllRules,
  createRule
}
