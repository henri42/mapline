// Store central de l'éditeur — état + pub/sub minimal, sans framework.
// Hydraté une fois depuis le payload JSON embarqué (#editor-payload). Tous les
// contrôleurs Stimulus de l'éditeur s'y branchent (pas d'outlets en cascade).
//
// Versionnement : `resolveStateAt` est le miroir (léger) du StateResolver Ruby.
// En M4 tout est mono-état (rattaché à la première date clé) ; la résolution
// carry-forward complète arrive avec M5.

// Fabrique un objet feature normalisé (states indexés par id de date clé).
function normalizeFeature(raw) {
  const states = new Map()
  const source = raw.states || {}
  for (const key of Object.keys(source)) {
    states.set(Number(key), source[key])
  }
  return {
    id: raw.id,
    featureType: raw.featureType,
    name: raw.name || '',
    zIndex: raw.zIndex || 0,
    style: raw.style || {},
    states,
  }
}

class EditorStore {
  constructor() {
    this.mapline = null
    this.keyDates = []
    this.currentKeyDateId = null
    this.features = new Map() // id -> feature
    this.selectedFeatureId = null
    this.currentTool = 'select'
    this.saveStatus = 'idle' // idle | saving | saved | error
    this.listeners = new Set()
    this.hydrated = false
  }

  subscribe(fn) {
    this.listeners.add(fn)
    return () => this.listeners.delete(fn)
  }

  emit(event = {}) {
    for (const fn of this.listeners) fn(event, this)
  }

  hydrateFromElement(el) {
    if (this.hydrated || !el) return
    const data = JSON.parse(el.textContent)
    this.mapline = data.mapline
    this.keyDates = data.keyDates || []
    this.currentKeyDateId = this.keyDates[0]?.id ?? null
    this.features = new Map((data.features || []).map((f) => [f.id, normalizeFeature(f)]))
    this.hydrated = true
    this.emit({ type: 'hydrated' })
  }

  // --- lectures ---
  get featureList() {
    return [...this.features.values()].sort((a, b) => a.zIndex - b.zIndex || a.id - b.id)
  }

  feature(id) {
    return this.features.get(id)
  }

  get selectedFeature() {
    return this.selectedFeatureId ? this.features.get(this.selectedFeatureId) : null
  }

  get hasKeyDates() {
    return this.currentKeyDateId != null
  }

  // État d'une feature à la date clé courante (mono-état en M4).
  resolveState(feature) {
    return feature.states.get(this.currentKeyDateId) || null
  }

  // --- mutations (émettent un évènement typé) ---
  setTool(tool) {
    this.currentTool = tool
    this.emit({ type: 'tool' })
  }

  select(id) {
    this.selectedFeatureId = id
    this.emit({ type: 'selection' })
  }

  upsertFeature(rawFeature) {
    this.features.set(rawFeature.id, normalizeFeature(rawFeature))
    this.emit({ type: 'features' })
  }

  removeFeature(id) {
    this.features.delete(id)
    if (this.selectedFeatureId === id) this.selectedFeatureId = null
    this.emit({ type: 'features' })
  }

  setState(featureId, keyDateId, body) {
    const feature = this.features.get(featureId)
    if (!feature) return
    feature.states.set(Number(keyDateId), body)
    this.emit({ type: 'features' })
  }

  setSaveStatus(status) {
    this.saveStatus = status
    this.emit({ type: 'save' })
  }
}

// Singleton partagé par tous les contrôleurs de l'éditeur.
export default new EditorStore()
