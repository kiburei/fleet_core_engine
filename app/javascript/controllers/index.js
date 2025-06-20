import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Import and register standard controllers
import HelloController from "./hello_controller"
import TestController from "./test_controller"
import CartController from "./cart_controller"
import CartViewController from "./cart_view_controller"

application.register("hello", HelloController)
application.register("test", TestController)
application.register("cart", CartController)
application.register("cart-view", CartViewController)

// Import RailsUI Stimulus components
import { 
  RailsuiModal, 
  RailsuiDropdown, 
  RailsuiTabs, 
  RailsuiTooltip,
  RailsuiToggle,
  RailsuiToast
} from 'railsui-stimulus'

// Register RailsUI controllers
application.register('railsui-modal', RailsuiModal)
application.register('railsui-dropdown', RailsuiDropdown)
application.register('railsui-tabs', RailsuiTabs)
application.register('railsui-tooltip', RailsuiTooltip)
application.register('railsui-toggle', RailsuiToggle)
application.register('railsui-toast', RailsuiToast)

console.log("Stimulus application started with controllers:", application.router.controllers.map(c => c.identifier))

export default application