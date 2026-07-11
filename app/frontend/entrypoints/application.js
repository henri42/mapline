// Entrypoint Vite de Mapline : Turbo + Stimulus (enregistrement automatique
// des contrôleurs) + styles globaux.
import '@hotwired/turbo'

import { Application } from '@hotwired/stimulus'
import { registerControllers } from 'stimulus-vite-helpers'

import '../styles/application.css'

const application = Application.start()

// Chaque fichier app/frontend/controllers/**/*_controller.js est enregistré
// automatiquement d'après son nom de fichier (miroir de stimulus-loading).
const controllers = import.meta.glob('../controllers/**/*_controller.js', { eager: true })
registerControllers(application, controllers)

window.Stimulus = application
