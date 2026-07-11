import { Controller } from '@hotwired/stimulus'
import store from '../../editor/store'
import { updateFeature } from '../../editor/api'

// Champs de style par type de feature (clé de style + rendu du champ).
const STYLE_FIELDS = {
  area: [
    { key: 'fill', label: 'Remplissage', type: 'color' },
    { key: 'fillOpacity', label: 'Opacité', type: 'number', min: 0, max: 1, step: 0.05 },
    { key: 'stroke', label: 'Contour', type: 'color' },
    { key: 'strokeWidth', label: 'Épaisseur', type: 'number', min: 0, max: 20, step: 0.5 },
  ],
  line: [
    { key: 'stroke', label: 'Couleur', type: 'color' },
    { key: 'strokeWidth', label: 'Épaisseur', type: 'number', min: 0, max: 20, step: 0.5 },
  ],
  arrow: [
    { key: 'stroke', label: 'Couleur', type: 'color' },
    { key: 'strokeWidth', label: 'Épaisseur', type: 'number', min: 0, max: 20, step: 0.5 },
  ],
  point: [
    { key: 'fill', label: 'Couleur', type: 'color' },
    { key: 'radius', label: 'Rayon', type: 'number', min: 1, max: 30, step: 1 },
    { key: 'stroke', label: 'Contour', type: 'color' },
    { key: 'strokeWidth', label: 'Épaisseur', type: 'number', min: 0, max: 20, step: 0.5 },
  ],
  label: [
    { key: 'textColor', label: 'Couleur du texte', type: 'color' },
    { key: 'textSize', label: 'Taille', type: 'number', min: 8, max: 48, step: 1 },
  ],
}
const NAME_LABEL = { label: 'Texte affiché' }

// Inspecteur : nom + style de la feature sélectionnée, et retouche de la forme.
// Ne se reconstruit que lorsque la sélection change (évite de perdre le focus
// pendant la saisie) ; les modifications sont enregistrées avec un léger debounce.
export default class extends Controller {
  static targets = ['body', 'empty']

  connect() {
    store.hydrateFromElement(document.getElementById('editor-payload'))
    this.editing = false
    this.renderedFeatureId = null
    this.unsubscribe = store.subscribe((event) => {
      if (['selection', 'features', 'hydrated'].includes(event.type)) this.render()
    })
    this.render()
  }

  disconnect() {
    this.unsubscribe?.()
    clearTimeout(this.saveTimer)
  }

  render() {
    const feature = store.selectedFeature
    this.bodyTarget.hidden = !feature
    this.emptyTarget.hidden = !!feature

    if (!feature) {
      this.renderedFeatureId = null
      return
    }
    if (feature.id === this.renderedFeatureId) return

    if (this.editing) this.stopEditing()
    this.renderedFeatureId = feature.id
    this.buildFields(feature)
  }

  buildFields(feature) {
    const fields = []

    fields.push(this.field({
      label: NAME_LABEL[feature.featureType] || 'Nom',
      input: this.textInput('name', feature.name || ''),
    }))

    for (const spec of STYLE_FIELDS[feature.featureType] || []) {
      const value = feature.style?.[spec.key]
      fields.push(this.field({ label: spec.label, input: this.styleInput(spec, value) }))
    }

    const shape = document.createElement('button')
    shape.type = 'button'
    shape.className = 'btn btn-ghost mt-2 text-sm'
    shape.textContent = 'Modifier la forme'
    shape.addEventListener('click', () => this.toggleShapeEdit(shape))

    this.bodyTarget.replaceChildren(...fields, shape)
    this.shapeButton = shape
  }

  field({ label, input }) {
    const wrapper = document.createElement('label')
    wrapper.className = 'flex items-center justify-between gap-3 text-sm'
    const span = document.createElement('span')
    span.className = 'text-muted'
    span.textContent = label
    wrapper.append(span, input)
    return wrapper
  }

  textInput(role, value) {
    const input = document.createElement('input')
    input.type = 'text'
    input.value = value
    input.dataset.role = role
    input.className = 'w-40 rounded-md border border-line bg-surface px-2 py-1 text-ink'
    input.addEventListener('input', () => this.scheduleSave())
    return input
  }

  styleInput(spec, value) {
    const input = document.createElement('input')
    input.type = spec.type
    input.dataset.styleKey = spec.key
    if (spec.type === 'color') {
      input.value = value || '#000000'
      input.className = 'h-8 w-14 cursor-pointer rounded border border-line'
    } else {
      input.value = value ?? ''
      if (spec.min != null) input.min = spec.min
      if (spec.max != null) input.max = spec.max
      if (spec.step != null) input.step = spec.step
      input.className = 'w-24 rounded-md border border-line bg-surface px-2 py-1 text-ink'
    }
    input.addEventListener('input', () => this.scheduleSave())
    return input
  }

  scheduleSave() {
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => this.save(), 300)
  }

  async save() {
    const feature = store.selectedFeature
    if (!feature) return

    const name = this.bodyTarget.querySelector('[data-role="name"]')?.value ?? feature.name
    const style = { ...feature.style }
    for (const input of this.bodyTarget.querySelectorAll('[data-style-key]')) {
      style[input.dataset.styleKey] = input.type === 'color' ? input.value : Number(input.value)
    }

    store.setSaveStatus('saving')
    try {
      const updated = await updateFeature(feature.id, { name, style })
      store.upsertFeature(updated)
      store.setSaveStatus('saved')
    } catch {
      store.setSaveStatus('error')
    }
  }

  toggleShapeEdit(button) {
    if (this.editing) this.stopEditing()
    else {
      this.editing = true
      document.dispatchEvent(new CustomEvent('editor:map-command', { detail: { action: 'editGeometry' } }))
      button.textContent = 'Terminer la forme'
      button.classList.add('btn-primary')
      button.classList.remove('btn-ghost')
    }
  }

  stopEditing() {
    this.editing = false
    document.dispatchEvent(new CustomEvent('editor:map-command', { detail: { action: 'finishEdit' } }))
    if (this.shapeButton) {
      this.shapeButton.textContent = 'Modifier la forme'
      this.shapeButton.classList.add('btn-ghost')
      this.shapeButton.classList.remove('btn-primary')
    }
  }
}
