const loadIfExists = path => {
  try {
    return require(path)
  } catch (err) {
    return {}
  }
}

const defaultConfig = loadIfExists("./default.js")
const environmentConfig = loadIfExists(`./${process.env.NODE_ENV}.js`)
const localConfig = loadIfExists("./local.js")

// Merge the configurations in order of specificity.
module.exports = Object.assign(
  {},
  defaultConfig,
  environmentConfig,
  localConfig
)
