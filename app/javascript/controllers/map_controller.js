import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    latitude: Number,
    longitude: Number,
    markers: Array, // Array of {lat, lng, label, color} objects
    zoom: { type: Number, default: 13 }
  }

  connect() {
    console.log('Map controller connected')
    console.log('Latitude:', this.latitudeValue)
    console.log('Longitude:', this.longitudeValue)
    console.log('Markers:', this.markersValue)
    
    // Import Leaflet CSS dynamically
    this.loadLeafletStyles()
    
    // Initialize the map after a short delay to ensure DOM is ready
    setTimeout(() => {
      this.initializeMap()
    }, 100)
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }

  loadLeafletStyles() {
    // Check if Leaflet CSS is already loaded
    if (!document.querySelector('link[href*="leaflet.css"]')) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
      link.integrity = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY='
      link.crossOrigin = ''
      document.head.appendChild(link)
    }
  }

  initializeMap() {
    // Set default icon paths for Leaflet (needed because of webpack/asset pipeline)
    delete L.Icon.Default.prototype._getIconUrl
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
      iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
    })

    // If markers are provided, use them for bounds, otherwise use single lat/lng
    if (this.hasMarkersValue && this.markersValue.length > 0) {
      this.initializeMapWithMarkers()
    } else if (this.hasLatitudeValue && this.hasLongitudeValue) {
      this.initializeMapWithSinglePoint()
    } else {
      console.error("Map controller requires either latitude/longitude or markers")
      return
    }
  }

  initializeMapWithSinglePoint() {
    // Create map centered on single point
    this.map = L.map(this.element).setView([this.latitudeValue, this.longitudeValue], this.zoomValue)

    // Add tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Add marker
    const marker = L.marker([this.latitudeValue, this.longitudeValue]).addTo(this.map)
    
    // Add popup if we have a label (from element data attribute)
    const label = this.element.dataset.label
    if (label) {
      marker.bindPopup(label).openPopup()
    }
  }

  initializeMapWithMarkers() {
    // Create map without initial center (we'll fit bounds)
    this.map = L.map(this.element)

    // Add tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Create custom icons for different marker types
    const greenIcon = new L.Icon({
      iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      shadowSize: [41, 41]
    })

    const redIcon = new L.Icon({
      iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      shadowSize: [41, 41]
    })

    const blueIcon = new L.Icon({
      iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      shadowSize: [41, 41]
    })

    // Add markers and collect bounds
    const bounds = []
    this.markersValue.forEach(markerData => {
      const { lat, lng, label, color } = markerData
      
      // Select icon based on color
      let icon
      if (color === 'green') {
        icon = greenIcon
      } else if (color === 'red') {
        icon = redIcon
      } else if (color === 'blue') {
        icon = blueIcon
      }

      const marker = L.marker([lat, lng], icon ? { icon } : {}).addTo(this.map)
      
      if (label) {
        marker.bindPopup(label)
      }

      bounds.push([lat, lng])
    })

    // Fit map to show all markers
    if (bounds.length > 0) {
      this.map.fitBounds(bounds, { padding: [50, 50] })
    }
  }
}
