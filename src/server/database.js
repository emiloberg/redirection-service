const Sequelize = require("sequelize")
const CONFIG = require("./config")

const sequelize = new Sequelize(CONFIG.DATABASE_URL)

const URI_REGEX = /^(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$/i
const PATH_REGEX = /^(\/[^\s\/]+)+$/i
const COUNTRY_TOKEN_REGEX = /\{country\}/gi

// NOTE: Remember to keep the validations below in sync with the client side validatinos in Rule.elm.
const Rule = sequelize.define(
  "rule",
  {
    id: { type: Sequelize.INTEGER, primaryKey: true },
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

          if (!PATH_REGEX.test(value)) {
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

          if (!PATH_REGEX.test(value) && !URI_REGEX.test(value)) {
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
        },
        asdf() {
          console.log("Why:", this.why)
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
