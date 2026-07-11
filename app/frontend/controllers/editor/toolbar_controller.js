import { Controller } from '@hotwired/stimulus'
import store from '../../editor/store'

// Sélecteur d'outil de dessin. Chaque bouton porte `data-tool` ; le clic met à
// jour le store (source de vérité), l'éditeur--map réagit en changeant de mode.
export default class extends Controller {
  static targets = ['tool']

  connect() {
    store.hydrateFromElement(document.getElementById('editor-payload'))
    this.unsubscribe = store.subscribe((event) => {
      if (event.type === 'tool' || event.type === 'hydrated') this.render()
    })
    this.render()
  }

  disconnect() {
    this.unsubscribe?.()
  }

  select(event) {
    const button = event.currentTarget
    if (button.disabled) return
    store.setTool(button.dataset.tool)
  }

  render() {
    for (const button of this.toolTargets) {
      const drawingTool = button.dataset.tool !== 'select'
      button.disabled = drawingTool && !store.hasKeyDates

      const active = button.dataset.tool === store.currentTool
      button.classList.toggle('ring-2', active)
      button.classList.toggle('ring-primary', active)
      button.classList.toggle('bg-canvas', active)
      button.setAttribute('aria-pressed', active ? 'true' : 'false')
    }
  }
}
