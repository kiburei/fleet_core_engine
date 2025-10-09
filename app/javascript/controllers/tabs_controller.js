import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]

  connect() {
    console.log('Tabs controller connected!')
    console.log('Element:', this.element)
    console.log('Tab targets found:', this.tabTargets.length)
    
    this.tabTargets.forEach((tab, index) => {
      console.log(`Tab ${index}:`, tab, 'data-tab:', tab.dataset.tab)
    })
    
    // Set initial active tab based on URL params
    const urlParams = new URLSearchParams(window.location.search)
    const currentStatus = urlParams.get('status') || this.getDefaultStatus()
    console.log('Current status:', currentStatus)
    this.updateActiveTab(currentStatus)
  }

  getDefaultStatus() {
    if (this.tabTargets.length > 0) {
      const firstTab = this.tabTargets[0]
      const defaultStatus = firstTab.dataset.tab || 'active'
      console.log('Default status:', defaultStatus)
      return defaultStatus
    }
    return 'active'
  }

  switch(event) {
    console.log('=== SWITCH METHOD CALLED ===')
    console.log('Event:', event)
    console.log('Current target:', event.currentTarget)
    
    event.preventDefault()
    
    const clickedTab = event.currentTarget
    const tabStatus = clickedTab.dataset.tab
    
    console.log('Switching to tab:', tabStatus)
    
    if (!tabStatus) {
      console.error('No tab status found on clicked element')
      return
    }
    
    // Create new URL with updated status
    const newUrl = new URL(window.location)
    const defaultStatus = this.getDefaultStatus()
    
    if (tabStatus === defaultStatus) {
      newUrl.searchParams.delete('status')
    } else {
      newUrl.searchParams.set('status', tabStatus)
    }
    
    // Reset pagination
    newUrl.searchParams.delete('page')
    
    console.log('Navigating to:', newUrl.toString())
    
    // Navigate to the new URL
    window.location.href = newUrl.toString()
  }

  updateActiveTab(status) {
    console.log('Updating active tab to:', status)
    
    this.tabTargets.forEach(tab => {
      const isActiveTab = tab.dataset.tab === status
      
      if (isActiveTab) {
        // Active tab styles
        tab.classList.add("bg-slate-50", "dark:bg-slate-900", "text-primary-600", "dark:text-primary-400")
        tab.classList.remove("hover:bg-slate-50", "hover:text-primary-600", "dark:hover:text-primary-400", "dark:text-slate-300", "dark:hover:bg-slate-900")
      } else {
        // Inactive tab styles
        tab.classList.remove("bg-slate-50", "dark:bg-slate-900", "text-primary-600", "dark:text-primary-400")
        tab.classList.add("hover:bg-slate-50", "hover:text-primary-600", "dark:hover:text-primary-400", "dark:text-slate-300", "dark:hover:bg-slate-900")
      }
    })
  }
}
