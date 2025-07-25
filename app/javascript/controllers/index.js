import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Import and register standard controllers
import HelloController from "./hello_controller"
import TestController from "./test_controller"
import CartController from "./cart_controller"
import CartViewController from "./cart_view_controller"

application.register("hello", HelloController)
application.register("test", TestController)
application.register("cart", CartController)
application.register("cart-view", CartViewController)

// Import custom RailsUI controllers
import ComboSelectController from "./railsui/combo_select_controller"
import DashboardController from "./railsui/dashboard_controller"
import NavController from "./railsui/nav_controller"

application.register("combo-select", ComboSelectController)
application.register("dashboard", DashboardController)
application.register("nav", NavController)

// Import and register RailsUI Stimulus controllers
import { 
  RailsuiClipboard, 
  RailsuiCountUp, 
  RailsuiCombobox, 
  RailsuiDateRangePicker, 
  RailsuiDropdown, 
  RailsuiModal, 
  RailsuiRange, 
  RailsuiReadMore,
  RailsuiSelectAll, 
  RailsuiTabs, 
  RailsuiToast, 
  RailsuiToggle, 
  RailsuiTooltip 
} from 'railsui-stimulus'

application.register('railsui-clipboard', RailsuiClipboard)
application.register('railsui-count-up', RailsuiCountUp)
application.register('railsui-combobox', RailsuiCombobox)
application.register('railsui-date-range-picker', RailsuiDateRangePicker)
application.register('railsui-dropdown', RailsuiDropdown)
application.register('railsui-modal', RailsuiModal)
application.register('railsui-range', RailsuiRange)
application.register('railsui-read-more', RailsuiReadMore)
application.register('railsui-select-all', RailsuiSelectAll)
application.register('railsui-tabs', RailsuiTabs)
application.register('railsui-toast', RailsuiToast)
application.register('railsui-toggle', RailsuiToggle)
application.register('railsui-tooltip', RailsuiTooltip)

console.log('Stimulus controllers registered:', Object.keys(application.router.controllersByIdentifier))

export default application
