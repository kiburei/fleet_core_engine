import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]

  switch(event) {
    const clickedTab = event.currentTarget
    const tabName = clickedTab.dataset.tab

    // Update tab appearance
    this.tabTargets.forEach(tab => {
      tab.classList.remove("border-primary-500", "text-primary-600", "dark:text-primary-400")
      tab.classList.add("border-transparent", "text-slate-500", "hover:text-slate-700", "hover:border-slate-300", "dark:text-slate-400", "dark:hover:text-slate-300")
    })

    clickedTab.classList.add("border-primary-500", "text-primary-600", "dark:text-primary-400")
    clickedTab.classList.remove("border-transparent", "text-slate-500", "hover:text-slate-700", "hover:border-slate-300", "dark:text-slate-400", "dark:hover:text-slate-300")

    // Update content visibility
    this.contentTargets.forEach(content => {
      if (content.dataset.tab === tabName) {
        content.classList.remove("hidden")
      } else {
        content.classList.add("hidden")
      }
    })
  }
}
