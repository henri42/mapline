import { Controller } from '@hotwired/stimulus'
import store from '../../editor/store'
import { deleteFeature } from '../../editor/api'

const TYPE_LABELS = {
  area: 'Zone', line: 'Ligne', arrow: 'Flèche', point: 'Point', label: 'Étiquette',
}

// Liste des éléments de la carte : sélection et suppression. (Les badges
// d'héritage viendront avec le versionnement en M5.)
export default class extends Controller {
  static targets = ['list', 'empty']

  connect() {
    store.hydrateFromElement(document.getElementById('editor-payload'))
    this.unsubscribe = store.subscribe((event) => {
      if (['features', 'selection', 'hydrated'].includes(event.type)) this.render()
    })
    this.render()
  }

  disconnect() {
    this.unsubscribe?.()
  }

  render() {
    const features = store.featureList
    this.emptyTarget.hidden = features.length > 0
    this.listTarget.replaceChildren(...features.map((feature) => this.row(feature)))
  }

  row(feature) {
    const selected = feature.id === store.selectedFeatureId
    const li = document.createElement('li')
    li.className = [
      'flex items-center justify-between gap-2 rounded-lg border px-3 py-2',
      selected ? 'border-primary bg-canvas' : 'border-line bg-surface',
    ].join(' ')

    const select = document.createElement('button')
    select.type = 'button'
    select.className = 'flex min-w-0 flex-1 items-center gap-2 text-left'
    select.addEventListener('click', () => store.select(feature.id))

    const badge = document.createElement('span')
    badge.className = 'shrink-0 rounded-full bg-line px-2 py-0.5 text-xs text-muted'
    badge.textContent = TYPE_LABELS[feature.featureType] || 'Élément'

    const name = document.createElement('span')
    name.className = 'truncate text-sm font-medium text-ink'
    name.textContent = feature.name || `${TYPE_LABELS[feature.featureType]} sans nom`

    select.append(badge, name)

    const remove = document.createElement('button')
    remove.type = 'button'
    remove.className = 'shrink-0 text-sm text-error-ink'
    remove.textContent = 'Supprimer'
    remove.addEventListener('click', () => this.remove(feature.id))

    li.append(select, remove)
    return li
  }

  async remove(id) {
    if (!window.confirm('Supprimer cet élément ?')) return
    store.setSaveStatus('saving')
    try {
      await deleteFeature(id)
      store.removeFeature(id)
      store.setSaveStatus('saved')
    } catch {
      store.setSaveStatus('error')
    }
  }
}
