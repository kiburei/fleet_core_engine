import { application } from "../application"

// Import local controllers
import ComboSelectController from "./combo_select_controller"
import DashboardController from "./dashboard_controller"
import NavController from "./nav_controller"
import DropdownController from "./dropdown_controller"

// Register local controllers
application.register("combo-select", ComboSelectController)
application.register("dashboard", DashboardController)
application.register("nav", NavController)
application.register("dropdown", DropdownController)

// Import and register railsui-stimulus controllers
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
