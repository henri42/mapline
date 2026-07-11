import { Controller } from '@hotwired/stimulus'
import store from '../../editor/store'

// Indicateur de sauvegarde optimiste : reflète store.saveStatus.
const LABELS = {
  idle: '',
  saving: 'Enregistrement…',
  saved: 'Enregistré ✓',
  error: "Échec de l'enregistrement",
}

export default class extends Controller {
  connect() {
    store.hydrateFromElement(document.getElementById('editor-payload'))
    this.unsubscribe = store.subscribe((event) => {
      if (event.type === 'save') this.render()
    })
    this.render()
  }

  disconnect() {
    this.unsubscribe?.()
  }

  render() {
    this.element.textContent = LABELS[store.saveStatus] || ''
    this.element.classList.toggle('text-error-ink', store.saveStatus === 'error')
    this.element.classList.toggle('text-muted', store.saveStatus !== 'error')
  }
}
