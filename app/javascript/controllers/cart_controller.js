import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { productId: Number, productName: String, price: Number }

  connect() {
    console.log("Cart controller connected")
  }

  addToCart() {
    // Get product details
    const productId = this.productIdValue || Math.floor(Math.random() * 1000)
    const productName = this.productNameValue || "Sample Product"
    const price = this.priceValue || 1999

    // Show success message
    this.showSuccessMessage(productName)
    
    // Optional: Add to localStorage cart
    this.addToLocalStorageCart(productId, productName, price)
    
    // Update button state temporarily
    this.updateButtonState()
  }

  showSuccessMessage(productName) {
    // Create a toast-like notification
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 bg-green-500 text-white px-6 py-3 rounded-lg shadow-lg z-50 transform transition-all duration-300'
    notification.innerHTML = `
      <div class="flex items-center gap-2">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span>${productName} added to cart!</span>
      </div>
    `
    
    document.body.appendChild(notification)
    
    // Remove notification after 3 seconds
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }

  addToLocalStorageCart(productId, productName, price) {
    let cart = JSON.parse(localStorage.getItem('marketplace_cart') || '[]')
    
    // Check if item already exists
    const existingItem = cart.find(item => item.id === productId)
    if (existingItem) {
      existingItem.quantity += 1
    } else {
      cart.push({
        id: productId,
        name: productName,
        price: price,
        quantity: 1
      })
    }
    
    localStorage.setItem('marketplace_cart', JSON.stringify(cart))
    console.log('Cart updated:', cart)
    
    
    document.dispatchEvent(new CustomEvent('cartUpdated'))
  }

  updateButtonState() {
    const button = this.buttonTarget
    const originalText = button.textContent
    
    button.textContent = 'Added!'
    button.classList.add('bg-green-600', 'hover:bg-green-700')
    button.classList.remove('bg-blue-600', 'hover:bg-blue-700')
    
    setTimeout(() => {
      button.textContent = originalText
      button.classList.remove('bg-green-600', 'hover:bg-green-700')
      button.classList.add('bg-blue-600', 'hover:bg-blue-700')
    }, 2000)
  }
} 