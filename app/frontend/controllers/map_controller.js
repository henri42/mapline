import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

import neutralStyle from '../styles/basemap-neutral.json'

// Carte MapLibre sur fond neutre.
//
// Lecture seule (page publique) : affiche la vue initiale de la carte.
// Éditeur (data-map-save-url-value présent) : le bouton « Définir la vue
// initiale » enregistre le centre/zoom courants via PATCH JSON.
export default class extends Controller {
  static targets = ['canvas', 'status']
  static values = {
    centerLng: Number,
    centerLat: Number,
    zoom: Number,
    saveUrl: String,
  }

  connect() {
    this.map = new maplibregl.Map({
      container: this.hasCanvasTarget ? this.canvasTarget : this.element,
      style: neutralStyle,
      center: [this.centerLngValue, this.centerLatValue],
      zoom: this.zoomValue,
      attributionControl: { compact: true },
    })
    this.map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right')
  }

  disconnect() {
    this.map?.remove()
    this.map = null
  }

  // Action éditeur : enregistre le centre/zoom courants comme vue initiale.
  async saveInitialView(event) {
    event.preventDefault()
    if (!this.hasSaveUrlValue || !this.map) return

    const center = this.map.getCenter()
    const payload = {
      mapline: {
        center_lng: round(center.lng, 6),
        center_lat: round(center.lat, 6),
        zoom: round(this.map.getZoom(), 2),
      },
    }

    this.setStatus('Enregistrement…')
    try {
      const response = await fetch(this.saveUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify(payload),
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      this.setStatus('Vue initiale enregistrée ✓')
    } catch (error) {
      this.setStatus("Échec de l'enregistrement")
    }
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}

function round(value, decimals) {
  return Number(value.toFixed(decimals))
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}
