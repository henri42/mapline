import { Controller } from '@hotwired/stimulus'

// Contrôleur de démonstration servant à vérifier l'enregistrement automatique
// des contrôleurs Stimulus via stimulus-vite-helpers.
export default class extends Controller {
  connect() {
    this.element.dataset.helloConnected = 'true'
  }
}
