import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "count", "items", "total"]

  connect() {
    console.log("Cart view controller connected")
    this.updateCartDisplay()
    
    
    document.addEventListener('cartUpdated', () => {
      this.updateCartDisplay()
    })
    
    
    document.addEventListener('click', (event) => {
      // Don't close if clicking inside the dropdown area
      if (!this.element.contains(event.target)) {
        this.closeCart()
      }
    })
    
    // Event listeners are now handled via Stimulus actions directly
  }

  toggleCart() {
    this.updateCartDisplay()
    if (this.dropdownTarget.classList.contains('hidden')) {
      this.openCart()
    } else {
      this.closeCart()
    }
  }

  openCart() {
    this.dropdownTarget.classList.remove('hidden')
  }

  closeCart() {
    this.dropdownTarget.classList.add('hidden')
  }

  updateCartDisplay() {
    const cart = this.getCart()
    const itemCount = cart.reduce((sum, item) => sum + item.quantity, 0)
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0)

    // Update cart count badge
    this.countTarget.textContent = itemCount
    this.countTarget.classList.toggle('hidden', itemCount === 0)

    // Update total
    this.totalTarget.textContent = `KES ${this.formatNumber(total)}`

    // Update cart items
    this.renderCartItems(cart)
  }

  renderCartItems(cart) {
    if (cart.length === 0) {
      this.itemsTarget.innerHTML = `
        <div class="p-8 text-center text-gray-500">
          <svg class="w-12 h-12 mx-auto mb-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
            <path d="M3 1a1 1 0 000 2h1.22l.305 1.222a.997.997 0 00.01.042l1.358 5.43-.893.892C3.74 11.846 4.632 14 6.414 14H15a1 1 0 000-2H6.414l1-1H14a1 1 0 00.894-.553l3-6A1 1 0 0017 3H6.28l-.31-1.243A1 1 0 005 1H3zM16 16.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM6.5 18a1.5 1.5 0 100-3 1.5 1.5 0 000 3z"/>
          </svg>
          <p>Your cart is empty</p>
        </div>
      `
      return
    }

    const itemsHTML = cart.map(item => `
      <div class="p-4 border-b border-gray-200 dark:border-slate-700 flex items-center justify-between">
        <div class="flex-1">
          <h4 class="font-medium text-slate-800 dark:text-white">${item.name}</h4>
          <p class="text-sm text-gray-500">KES ${this.formatNumber(item.price)} each</p>
        </div>
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2">
            <button data-action="click->cart-view#decreaseQuantity" 
                    data-cart-view-item-id-param="${item.id}"
                    class="w-8 h-8 bg-red-100 hover:bg-red-200 border border-red-300 hover:border-red-400 rounded-full flex items-center justify-center text-lg font-bold text-red-600 hover:text-red-700 transition-all duration-200 shadow-sm hover:shadow-md">
              −
            </button>
            <span class="w-10 text-center font-semibold text-slate-700 dark:text-slate-300">${item.quantity}</span>
            <button data-action="click->cart-view#increaseQuantity" 
                    data-cart-view-item-id-param="${item.id}"
                    class="w-8 h-8 bg-green-100 hover:bg-green-200 border border-green-300 hover:border-green-400 rounded-full flex items-center justify-center text-lg font-bold text-green-600 hover:text-green-700 transition-all duration-200 shadow-sm hover:shadow-md">
              +
            </button>
          </div>
          <button data-action="click->cart-view#removeItem" 
                  data-cart-view-item-id-param="${item.id}"
                  class="text-red-500 hover:text-red-700 p-1">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
      </div>
    `).join('')

    this.itemsTarget.innerHTML = itemsHTML
  }

  // Event listeners for cart modifications
  increaseQuantity(event) {
    event.stopPropagation() // Prevent event bubbling
    const itemId = parseInt(event.params.itemId)
    this.modifyQuantity(itemId, 1)
  }

  decreaseQuantity(event) {
    event.stopPropagation() // Prevent event bubbling
    const itemId = parseInt(event.params.itemId)
    this.modifyQuantity(itemId, -1)
  }

  removeItem(event) {
    event.stopPropagation() // Prevent event bubbling
    const itemId = parseInt(event.params.itemId)
    let cart = this.getCart()
    cart = cart.filter(item => item.id !== itemId)
    this.saveCart(cart)
    this.updateCartDisplay()
    this.showNotification(`Item removed from cart`, 'info')
  }

  modifyQuantity(itemId, change) {
    let cart = this.getCart()
    const item = cart.find(item => item.id === itemId)
    
    if (item) {
      item.quantity += change
      if (item.quantity <= 0) {
        cart = cart.filter(item => item.id !== itemId)
      }
    }
    
    this.saveCart(cart)
    this.updateCartDisplay()
  }

  clearCart(event) {
    event.stopPropagation() // Prevent event bubbling
    if (confirm('Are you sure you want to clear your cart?')) {
      localStorage.removeItem('marketplace_cart')
      this.updateCartDisplay()
      this.showNotification('Cart cleared', 'info')
    }
  }

  checkout(event) {
    event.stopPropagation() // Prevent event bubbling
    const cart = this.getCart()
    if (cart.length === 0) {
      alert('Your cart is empty!')
      return
    }

    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0)
    const itemSummary = cart.map(item => `${item.quantity}x ${item.name}`).join('\n')
    
    if (confirm(`Proceed to checkout?\n\n${itemSummary}\n\nTotal: KES ${this.formatNumber(total)}`)) {
      // Here you would normally redirect to a checkout page or integrate with a payment system
      this.showNotification('Redirecting to checkout...', 'success')
      
      // For demo purposes, we'll just simulate a successful checkout
      setTimeout(() => {
        alert('Checkout successful! (This is a demo)')
        localStorage.removeItem('marketplace_cart')
        this.updateCartDisplay()
        this.closeCart()
      }, 1500)
    }
  }

  // Helper methods
  getCart() {
    return JSON.parse(localStorage.getItem('marketplace_cart') || '[]')
  }

  saveCart(cart) {
    localStorage.setItem('marketplace_cart', JSON.stringify(cart))
    // Dispatch event to notify other controllers
    document.dispatchEvent(new CustomEvent('cartUpdated'))
  }

  formatNumber(number) {
    return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')
  }

  showNotification(message, type = 'success') {
    const bgColor = type === 'success' ? 'bg-green-500' : type === 'info' ? 'bg-blue-500' : 'bg-red-500'
    
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 ${bgColor} text-white px-6 py-3 rounded-lg shadow-lg z-50 transform transition-all duration-300`
    notification.innerHTML = `
      <div class="flex items-center gap-2">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span>${message}</span>
      </div>
    `
    
    document.body.appendChild(notification)
    
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }
} 