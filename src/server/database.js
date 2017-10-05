const Sequelize = require("sequelize")
const CONFIG = require("./config")

const sequelize = new Sequelize(CONFIG.DATABASE_URL)

const URI_REGEX = /^(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$/i
const PATH_REGEX = /^(\/[^\s\/]+)+$/i

const Rule = sequelize.define(
  "rule",
  {
    id: { type: Sequelize.INTEGER, primaryKey: true },
    from: {
      type: Sequelize.STRING,
      validate: {
        pathOrUri(value) {
          if (!PATH_REGEX.test(value) || !URI_REGEX.test(value)) {
            throw new Error(
              'Value has to be either a path (e.g. "/foo/bar") or a URI (e.g. "http://foo.bar/baz")'
            )
          }
        }
      }
    },
    to: {
      type: Sequelize.STRING,
      validate: {
        is: PATH_REGEX
      }
    },
    kind: {
      type: Sequelize.STRING,
      validate: {
        isIn: [["Temporary", "Permanent"]]
      }
    },
    why: { type: Sequelize.STRING },
    who: { type: Sequelize.STRING },
    isRegex: { type: Sequelize.BOOLEAN, field: "is_regex" }
  },
  {
    createdAt: "created",
    updatedAt: "updated"
  }
)

async function getAllRules() {
  return await Rule.findAll()
}

async function createRule(rule, user) {
  return await Rule.create(
    {
      ...rule,
      who: user
    },
    { fields: ["from", "to", "kind", "why", "who", "isRegex"] }
  )
}

async function updateRule(ruleId, rule, user) {
  //TODO: Set updatedAt
  const res = await Rule.update(
    {
      ...rule,
      who: user
    },
    {
      returning: true,
      where: {
        id: ruleId
      }
    }
  )

  return res[1][0] //todo safeguard against this not existing
}

async function deleteRule(ruleId) {
  const rule = await Rule.findById(ruleId)

  if (rule) {
    await rule.destroy()
  }
}

module.exports = {
  getAllRules,
  createRule,
  updateRule,
  deleteRule
}
