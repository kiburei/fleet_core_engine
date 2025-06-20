import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Test controller connected!")
    this.element.style.backgroundColor = "lightgreen"
  }

  click() {
    alert("Test button clicked! Stimulus is working.")
  }
} 