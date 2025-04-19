import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "template"]

  addItem(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.itemsTarget.insertAdjacentHTML("beforeend", content)
  }

  removeItem(event) {
    event.preventDefault()
    const wrapper = event.target.closest("[data-manifest-item-wrapper]")
    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.querySelector("input[name*='_destroy']").value = "1"
      wrapper.style.display = "none"
    }
  }
}
