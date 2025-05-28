import { Controller } from "@hotwired/stimulus"
import { useTransition } from "stimulus-use"

// This is a backup controller in case the railsui-dropdown doesn't work
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    useTransition(this, {
      element: this.menuTarget
    })
    
    console.log("Dropdown controller connected")
  }

  toggle(event) {
    event.stopPropagation()
    this.toggleTransition()
  }

  hide(event) {
    if (this.element.contains(event.target)) return
    this.leave()
  }
} 