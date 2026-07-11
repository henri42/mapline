// Rendu MapLibre des features persistées (le reste que Terra Draw ne porte pas).
// Quatre sources GeoJSON (areas / lines / points / labels) + une source dérivée
// pour les têtes de flèches, avec styles pilotés par les propriétés des features.

export const FONT = ['Noto Sans Regular']
const SELECTED_COLOR = '#f59e0b' // ambre : surbrillance de la sélection

export const SOURCE_IDS = ['ml-areas', 'ml-lines', 'ml-points', 'ml-labels', 'ml-arrowheads']

// Largeur de trait, +2 si la feature est sélectionnée.
const widened = (base) => ['case', ['get', 'selected'], ['+', base, 2], base]
const strokeColor = ['case', ['get', 'selected'], SELECTED_COLOR, ['get', 'stroke']]

export function addSourcesAndLayers(map) {
  for (const id of SOURCE_IDS) {
    map.addSource(id, { type: 'geojson', data: emptyCollection() })
  }

  map.addLayer({
    id: 'ml-areas-fill', type: 'fill', source: 'ml-areas',
    paint: { 'fill-color': ['get', 'fill'], 'fill-opacity': ['get', 'fillOpacity'] },
  })
  map.addLayer({
    id: 'ml-areas-outline', type: 'line', source: 'ml-areas',
    paint: { 'line-color': strokeColor, 'line-width': widened(['get', 'strokeWidth']) },
  })
  map.addLayer({
    id: 'ml-lines', type: 'line', source: 'ml-lines',
    layout: { 'line-cap': 'round', 'line-join': 'round' },
    paint: { 'line-color': strokeColor, 'line-width': widened(['get', 'strokeWidth']) },
  })
  map.addLayer({
    id: 'ml-arrowheads', type: 'symbol', source: 'ml-arrowheads',
    layout: {
      'text-field': '▲', 'text-font': FONT, 'text-size': ['get', 'size'],
      'text-rotate': ['get', 'bearing'], 'text-rotation-alignment': 'map',
      'text-allow-overlap': true, 'text-ignore-placement': true,
    },
    paint: { 'text-color': ['get', 'color'] },
  })
  map.addLayer({
    id: 'ml-points', type: 'circle', source: 'ml-points',
    paint: {
      'circle-radius': ['get', 'radius'], 'circle-color': ['get', 'fill'],
      'circle-stroke-color': strokeColor, 'circle-stroke-width': widened(['get', 'strokeWidth']),
    },
  })
  map.addLayer({
    id: 'ml-labels', type: 'symbol', source: 'ml-labels',
    layout: {
      'text-field': ['get', 'text'], 'text-font': FONT, 'text-size': ['get', 'textSize'],
      'text-anchor': 'top', 'text-offset': [0, 0.4],
    },
    paint: {
      'text-color': ['get', 'textColor'],
      'text-halo-color': '#ffffff', 'text-halo-width': 1.5,
    },
  })
}

// Couches cliquables pour la sélection au clic sur la carte.
export const INTERACTIVE_LAYERS = ['ml-areas-fill', 'ml-lines', 'ml-points', 'ml-labels']

// Recalcule les données des sources depuis le store et les pousse dans la carte.
// `excludeId` : feature actuellement éditée par Terra Draw (rendue par lui).
export function refreshSources(map, store, excludeId = null) {
  const areas = [], lines = [], points = [], labels = [], arrowheads = []

  for (const feature of store.featureList) {
    if (feature.id === excludeId) continue
    const state = store.resolveState(feature)
    if (!state || state.visible === false || !state.geometry) continue

    const selected = feature.id === store.selectedFeatureId
    const gj = toGeoJSON(feature, state.geometry, selected)

    switch (feature.featureType) {
      case 'area':
        areas.push(gj); break
      case 'line':
        lines.push(gj); break
      case 'arrow':
        lines.push(gj)
        arrowheads.push(...arrowheadsFor(feature, state.geometry)); break
      case 'point':
        points.push(gj); break
      case 'label':
        labels.push(gj); break
    }
  }

  setData(map, 'ml-areas', areas)
  setData(map, 'ml-lines', lines)
  setData(map, 'ml-points', points)
  setData(map, 'ml-labels', labels)
  setData(map, 'ml-arrowheads', arrowheads)
}

function toGeoJSON(feature, geometry, selected) {
  const s = feature.style || {}
  return {
    type: 'Feature',
    id: feature.id,
    geometry,
    properties: {
      id: feature.id,
      selected,
      fill: s.fill || '#3b82f6',
      fillOpacity: s.fillOpacity ?? 0.35,
      stroke: s.stroke || '#1d4ed8',
      strokeWidth: s.strokeWidth ?? 2,
      radius: s.radius ?? 6,
      text: feature.name || '',
      textSize: s.textSize ?? 14,
      textColor: s.textColor || '#1c1b1a',
    },
  }
}

// Une tête de flèche au dernier sommet, orientée selon le dernier segment.
function arrowheadsFor(feature, geometry) {
  const coords = geometry?.coordinates
  if (!coords || coords.length < 2) return []
  const end = coords[coords.length - 1]
  const prev = coords[coords.length - 2]
  return [{
    type: 'Feature',
    geometry: { type: 'Point', coordinates: end },
    properties: {
      bearing: bearing(prev, end),
      color: feature.style?.stroke || '#b91c1c',
      size: (feature.style?.strokeWidth ?? 3) * 5,
    },
  }]
}

function bearing([lng1, lat1], [lng2, lat2]) {
  const toRad = (d) => (d * Math.PI) / 180
  const toDeg = (r) => (r * 180) / Math.PI
  const dLng = toRad(lng2 - lng1)
  const y = Math.sin(dLng) * Math.cos(toRad(lat2))
  const x = Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(dLng)
  return (toDeg(Math.atan2(y, x)) + 360) % 360
}

function setData(map, id, features) {
  map.getSource(id)?.setData({ type: 'FeatureCollection', features })
}

function emptyCollection() {
  return { type: 'FeatureCollection', features: [] }
}
