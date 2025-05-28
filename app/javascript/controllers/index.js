import { application } from "./application"

// Load all the controllers within this directory and all subdirectories. 
// Controller files must be named *_controller.js.
const standardControllers = require.context('.', true, /_controller\.js$/)
standardControllers.keys().forEach((controllerPath) => {
  if (controllerPath.includes('railsui/')) return
  const controller = standardControllers(controllerPath)
  const controllerName = controllerPath
    .replace(/^\.\//, '')
    .replace(/_controller\.js$/, '')
    .replace(/\//g, '--')
  application.register(controllerName, controller.default)
})

// Import railsui controllers explicitly
import "./railsui"

export { application }