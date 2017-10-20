const Sequelize = require("sequelize")
const CONFIG = require("./config")
const urlModule = require("url")

// To keep DRY and maintain compatibility with heroku we parse the database
// initialization data from the DATABASE_URL variable.
const databaseUrl = urlModule.parse(CONFIG.DATABASE_URL)
const databaseUsername = databaseUrl.auth
  ? databaseUrl.auth.split(":")[0]
  : null
const databasePassword = databaseUrl.auth
  ? databaseUrl.auth.split(":")[1]
  : null
const databaseName = databaseUrl.pathname.replace("/", "")
const sequalizeOptions = {
  dialect: "postgres",
  host: databaseUrl.hostname,
  port: parseInt(databaseUrl.port, 10),
  logging: process.env.NODE_ENV === "production" ? null : console.log
}

const sequelize = new Sequelize(
  databaseName,
  databaseUsername,
  databasePassword,
  sequalizeOptions
)

const URI_REGEX = /^(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$/i
const PATH_REGEX = /^(\/[^\s\/]+)+$/i
const COUNTRY_TOKEN_REGEX = /\{country\}/gi

const trimIfExists = str => {
  if (str && typeof str === "string") {
    return str.trim()
  }

  return str
}

// Here we define the structure of the model.
//
// NOTE: This has to be manually synced with the schema.
const Rule = sequelize.define(
  "rule",
  {
    id: { type: Sequelize.INTEGER, primaryKey: true, unique: true },
    from: {
      type: Sequelize.STRING,
      allowNull: false,
      validate: {
        notEmpty: {
          msg: '"From" can not be empty.'
        },
        path(value) {
          if (this.isRegex) {
            return
          }

          if (!(value === "/" || PATH_REGEX.test(value))) {
            throw new Error('"From" has to be a path (e.g. "/foo/bar").')
          }
        },
        countryToken(value) {
          if (!this.isRegex && COUNTRY_TOKEN_REGEX.test(value)) {
            throw new Error('"{country}" can only be used in regex rules.')
          }
        }
      }
    },
    to: {
      type: Sequelize.STRING,
      allowNull: false,
      notEmpty: {
        msg: '"To" can not be empty.'
      },
      validate: {
        pathOrUri(value) {
          if (this.isRegex) {
            return
          }

          if (
            !(value === "/" || PATH_REGEX.test(value) || URI_REGEX.test(value))
          ) {
            throw new Error(
              '"To" has to be either a path (e.g. "/foo/bar") or a URI (e.g. "http://foo.bar/baz").'
            )
          }
        }
      },
      countryToken(value) {
        if (!this.isRegex && COUNTRY_TOKEN_REGEX.test(value)) {
          throw new Error('"{country}" can only be used in regex rules.')
        }
      }
    },
    kind: {
      type: Sequelize.STRING,
      allowNull: false,
      validate: {
        isIn: {
          args: [["Temporary", "Permanent"]],
          msg: 'The only valid types are "Temporary" and "Permanent".'
        }
      }
    },
    why: {
      type: Sequelize.STRING,
      allowNull: false,
      validate: {
        len: {
          args: [20],
          msg: "Please elaborate on the purpose of the rule."
        }
      }
    },
    who: { type: Sequelize.STRING, allowNull: false },
    isRegex: {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "is_regex"
    }
  },
  {
    createdAt: "created",
    updatedAt: "updated",
    hooks: {
      beforeValidate: rule => {
        rule.from = trimIfExists(rule.from)
        rule.to = trimIfExists(rule.to)
        rule.why = trimIfExists(rule.why)
      }
    }
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

  try {
    return res[1][0]
  } catch (err) {
    return undefined
  }
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
