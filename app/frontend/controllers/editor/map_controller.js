import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import {
  TerraDraw,
  TerraDrawPolygonMode,
  TerraDrawLineStringMode,
  TerraDrawPointMode,
  TerraDrawSelectMode,
} from 'terra-draw'
import { TerraDrawMapLibreGLAdapter } from 'terra-draw-maplibre-gl-adapter'

import neutralStyle from '../../styles/basemap-neutral.json'
import store from '../../editor/store'
import { createFeature, putState } from '../../editor/api'
import { addSourcesAndLayers, refreshSources, INTERACTIVE_LAYERS } from '../../editor/layers'

// Outil courant → mode Terra Draw + type de feature à créer.
const TOOLS = {
  select: {},
  area: { mode: 'polygon', featureType: 'area' },
  line: { mode: 'linestring', featureType: 'line' },
  arrow: { mode: 'linestring', featureType: 'arrow' },
  point: { mode: 'point', featureType: 'point' },
  label: { mode: 'point', featureType: 'label' },
}
const DRAW_MODE_FOR_TYPE = {
  area: 'polygon', line: 'linestring', arrow: 'linestring', point: 'point', label: 'point',
}

// Contrôleur central de l'éditeur : MapLibre + Terra Draw, branché sur le store.
// Terra Draw ne porte que la feature en cours d'édition ; les features persistées
// sont rendues en couches MapLibre normales (voir editor/layers.js).
export default class extends Controller {
  static targets = ['canvas', 'viewStatus']
  static values = { centerLng: Number, centerLat: Number, zoom: Number, saveUrl: String }

  connect() {
    store.hydrateFromElement(document.getElementById('editor-payload'))
    this.editSession = null

    this.map = new maplibregl.Map({
      container: this.canvasTarget,
      style: neutralStyle,
      center: [this.centerLngValue, this.centerLatValue],
      zoom: this.zoomValue,
      attributionControl: { compact: true },
    })
    this.map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right')
    this.map.on('load', () => this.onMapLoad())

    this.onCommand = (event) => this.handleCommand(event.detail?.action)
    document.addEventListener('editor:map-command', this.onCommand)
    this.unsubscribe = store.subscribe((event) => this.onStoreEvent(event))
  }

  disconnect() {
    this.unsubscribe?.()
    document.removeEventListener('editor:map-command', this.onCommand)
    clearTimeout(this.autosaveTimer)
    try { this.draw?.stop() } catch { /* déjà arrêté */ }
    this.map?.remove()
    this.map = this.draw = null
    this.ready = false
  }

  onMapLoad() {
    addSourcesAndLayers(this.map)

    this.draw = new TerraDraw({
      adapter: new TerraDrawMapLibreGLAdapter({ map: this.map }),
      modes: [
        new TerraDrawPolygonMode(),
        new TerraDrawLineStringMode(),
        new TerraDrawPointMode(),
        new TerraDrawSelectMode({ flags: selectFlags() }),
      ],
    })
    this.draw.start()
    this.draw.setMode('static')
    this.draw.on('finish', (id) => this.onDrawFinish(id))
    this.draw.on('change', (ids) => this.onDrawChange(ids))

    this.map.on('click', (event) => this.onMapClick(event))

    this.ready = true
    this.applyTool()
    this.refresh()
    this.element.setAttribute('data-map-ready', 'true') // repère pour les tests système
  }

  onStoreEvent(event) {
    if (!this.ready) return
    if (event.type === 'tool') this.applyTool()
    else if (['features', 'selection', 'hydrated'].includes(event.type)) this.refresh()
  }

  refresh() {
    if (this.ready) refreshSources(this.map, store, this.editSession?.dbId ?? null)
  }

  applyTool() {
    if (!this.ready || this.editSession) return
    this.draw.setMode(TOOLS[store.currentTool]?.mode || 'static')
  }

  onMapClick(event) {
    if (!this.ready || this.editSession || store.currentTool !== 'select') return
    const hits = this.map.queryRenderedFeatures(event.point, { layers: INTERACTIVE_LAYERS })
    store.select(hits.length ? hits[0].properties.id : null)
  }

  // Fin d'un tracé : persiste la feature + son premier état, puis retire le
  // tracé temporaire de Terra Draw (désormais rendu en couche MapLibre).
  async onDrawFinish(id) {
    if (this.editSession) return
    const conf = TOOLS[store.currentTool]
    const drawn = this.draw.getSnapshot().find((f) => f.id === id)
    this.draw.removeFeatures([id])
    if (!conf?.featureType || !drawn || !store.hasKeyDates) return

    store.setSaveStatus('saving')
    try {
      const feature = await createFeature(store.mapline.id, {
        feature_type: conf.featureType,
        state: { key_date_id: store.currentKeyDateId, geometry: drawn.geometry },
      })
      store.upsertFeature(feature)
      store.select(feature.id)
      store.setSaveStatus('saved')
    } catch {
      store.setSaveStatus('error')
    }
  }

  onDrawChange(ids) {
    if (!this.editSession || !ids.includes(this.editSession.drawId)) return
    clearTimeout(this.autosaveTimer)
    this.autosaveTimer = setTimeout(() => this.autosaveGeometry(), 800)
  }

  async autosaveGeometry() {
    const session = this.editSession
    const snap = session && this.draw.getSnapshot().find((f) => f.id === session.drawId)
    if (!snap) return

    store.setSaveStatus('saving')
    try {
      const body = await putState(session.dbId, store.currentKeyDateId, { geometry: snap.geometry })
      store.setState(session.dbId, store.currentKeyDateId, {
        geometry: body.geometry, styleOverride: body.styleOverride, visible: body.visible,
      })
      store.setSaveStatus('saved')
    } catch {
      store.setSaveStatus('error')
    }
  }

  handleCommand(action) {
    if (action === 'editGeometry') this.startGeometryEdit()
    else if (action === 'finishEdit') this.finishGeometryEdit()
  }

  // Charge la feature sélectionnée dans Terra Draw pour retoucher sa géométrie.
  startGeometryEdit() {
    if (!this.ready || this.editSession) return
    const feature = store.selectedFeature
    const state = feature && store.resolveState(feature)
    if (!state?.geometry) return

    const before = new Set(this.draw.getSnapshot().map((f) => f.id))
    this.draw.addFeatures([{
      type: 'Feature',
      geometry: state.geometry,
      properties: { mode: DRAW_MODE_FOR_TYPE[feature.featureType] },
    }])
    const added = this.draw.getSnapshot().find((f) => !before.has(f.id))
    if (!added) return

    this.editSession = { dbId: feature.id, drawId: added.id }
    this.refresh() // masque la feature de la couche (Terra Draw la rend)
    this.draw.setMode('select')
    this.draw.selectFeature(added.id)
  }

  async finishGeometryEdit() {
    const session = this.editSession
    if (!session) return
    clearTimeout(this.autosaveTimer)
    await this.autosaveGeometry()
    try { this.draw.removeFeatures([session.drawId]) } catch { /* déjà retirée */ }
    this.editSession = null
    this.applyToolAfterEdit()
    this.refresh()
  }

  applyToolAfterEdit() {
    this.draw.setMode(TOOLS[store.currentTool]?.mode || 'static')
  }

  // Bouton « Définir la vue initiale » (repris de M2).
  async saveInitialView(event) {
    event.preventDefault()
    if (!this.hasSaveUrlValue || !this.map) return

    const center = this.map.getCenter()
    this.setViewStatus('Enregistrement…')
    try {
      const response = await fetch(this.saveUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json', Accept: 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify({
          mapline: {
            center_lng: round(center.lng, 6),
            center_lat: round(center.lat, 6),
            zoom: round(this.map.getZoom(), 2),
          },
        }),
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      this.setViewStatus('Vue initiale enregistrée ✓')
    } catch {
      this.setViewStatus("Échec de l'enregistrement")
    }
  }

  setViewStatus(text) {
    if (this.hasViewStatusTarget) this.viewStatusTarget.textContent = text
  }
}

// Autorise déplacement de la feature et édition des sommets en mode select.
function selectFlags() {
  const polygonal = {
    feature: {
      draggable: true,
      coordinates: { midpoints: true, draggable: true, deletable: true },
    },
  }
  return {
    polygon: polygonal,
    linestring: polygonal,
    point: { feature: { draggable: true } },
  }
}

function round(value, decimals) {
  return Number(value.toFixed(decimals))
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}
