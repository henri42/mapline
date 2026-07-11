// Petit client fetch pour les endpoints JSON de l'éditeur (namespace Editor::).
// Ajoute le jeton CSRF et normalise les erreurs (tableau `errors` renvoyé par
// le serveur → propriété `.errors` sur l'exception).

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

async function request(url, method, body) {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  if (!response.ok) {
    let errors = [`Erreur ${response.status}`]
    try {
      const payload = await response.json()
      if (Array.isArray(payload.errors)) errors = payload.errors
    } catch {
      /* réponse sans corps JSON */
    }
    const error = new Error(errors.join(' · '))
    error.errors = errors
    throw error
  }

  return response.status === 204 ? null : response.json()
}

export function createFeature(maplineId, feature) {
  return request(`/editor/maplines/${maplineId}/features`, 'POST', { feature })
}

export function updateFeature(id, feature) {
  return request(`/editor/features/${id}`, 'PATCH', { feature })
}

export function deleteFeature(id) {
  return request(`/editor/features/${id}`, 'DELETE')
}

export function putState(featureId, keyDateId, state) {
  return request(`/editor/features/${featureId}/states/${keyDateId}`, 'PUT', { state })
}

export function deleteState(featureId, keyDateId) {
  return request(`/editor/features/${featureId}/states/${keyDateId}`, 'DELETE')
}
