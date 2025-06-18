import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()

// Register standard controllers
const context = require.context(".", true, /_controller\.js$/)
application.load(definitionsFromContext(context))

// Register railsui controllers if they exist
try {
  const railsuiContext = require.context("./railsui", true, /_controller\.js$/)
  application.load(definitionsFromContext(railsuiContext))
} catch (e) {
  console.log("No Railsui controllers found")
}

export default application