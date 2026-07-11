import { Controller } from '@hotwired/stimulus'

// Frise chronologique partagée éditeur / lecteur.
//
// Espacement uniforme (v1) : la graduation d'index i est à i/(n-1) de la piste.
// Interactions : clic sur une graduation, glisser avec aimantation sur la plus
// proche, flèches clavier (← →) et boutons préc./suiv. À chaque changement de
// date courante, émet `timeline:change` (détail : { index, sortKey, keyDateId })
// que la carte écoutera aux jalons suivants, et met à jour le panneau contextuel.
export default class extends Controller {
  static targets = ['track', 'tick', 'cursor', 'date', 'title', 'description', 'previous', 'next']
  static values = { current: Number }

  connect() {
    this.dragging = false
    this.layoutTicks()
    this.select(this.currentValue, { animate: false, notify: false })
    this.element.addEventListener('keydown', this.onKeydown)
  }

  disconnect() {
    this.element.removeEventListener('keydown', this.onKeydown)
  }

  // Positionne chaque graduation à une fraction uniforme de la piste.
  layoutTicks() {
    this.tickTargets.forEach((tick) => {
      tick.style.left = `${this.fractionFor(this.indexOf(tick)) * 100}%`
    })
  }

  selectTick(event) {
    this.select(this.indexOf(event.currentTarget))
  }

  previous() {
    this.select(this.currentValue - 1)
  }

  next() {
    this.select(this.currentValue + 1)
  }

  onKeydown = (event) => {
    if (event.key === 'ArrowLeft') {
      event.preventDefault()
      this.previous()
    } else if (event.key === 'ArrowRight') {
      event.preventDefault()
      this.next()
    }
  }

  startDrag(event) {
    if (this.count < 2) return
    this.dragging = true
    this.trackTarget.setPointerCapture?.(event.pointerId)
    this.select(this.nearestIndex(event))
  }

  drag(event) {
    if (!this.dragging) return
    this.select(this.nearestIndex(event))
  }

  endDrag() {
    this.dragging = false
  }

  // Coeur : borne l'index, déplace le curseur, met à jour le panneau, émet l'évènement.
  select(index, { animate = true, notify = true } = {}) {
    const clamped = Math.max(0, Math.min(index, this.count - 1))
    this.currentValue = clamped

    const cursor = this.cursorTarget
    cursor.style.transitionDuration = animate ? '' : '0ms'
    cursor.style.left = `${this.fractionFor(clamped) * 100}%`

    this.tickTargets.forEach((tick, i) => {
      tick.classList.toggle('bg-primary', i === clamped)
      tick.classList.toggle('bg-muted', i !== clamped)
    })

    const tick = this.tickTargets[clamped]
    if (tick) this.updatePanel(tick.dataset)

    if (this.hasPreviousTarget) this.previousTarget.disabled = clamped === 0
    if (this.hasNextTarget) this.nextTarget.disabled = clamped === this.count - 1

    if (notify && tick) {
      this.dispatch('change', {
        detail: {
          index: clamped,
          sortKey: Number(tick.dataset.sortKey),
          keyDateId: Number(tick.dataset.keyDateId),
        },
      })
    }
  }

  updatePanel(data) {
    if (this.hasDateTarget) this.dateTarget.textContent = data.date || ''
    if (this.hasTitleTarget) this.titleTarget.textContent = data.title || ''
    if (this.hasDescriptionTarget) this.descriptionTarget.textContent = data.description || ''
  }

  // Graduation la plus proche de la position du pointeur (aimantation).
  nearestIndex(event) {
    const rect = this.trackTarget.getBoundingClientRect()
    const fraction = Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width))
    return Math.round(fraction * (this.count - 1))
  }

  fractionFor(index) {
    return this.count < 2 ? 0.5 : index / (this.count - 1)
  }

  indexOf(tick) {
    return Number(tick.dataset.index)
  }

  get count() {
    return this.tickTargets.length
  }
}
