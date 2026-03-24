/**
 * FocusTrack — Service Worker (Manifest V3)
 *
 * Escucha cambios de pestaña activa y envía la URL + título al servidor
 * local de FocusTrack en localhost:27432.
 */

const SERVER_URL = 'http://localhost:27432/activity';
const DEBOUNCE_MS = 1500; // Espera antes de reportar (evita spam en navegación rápida)

let debounceTimer = null;

async function reportActivity(url, title) {
  // No reportar páginas internas del navegador
  if (!url || url.startsWith('chrome://') || url.startsWith('chrome-extension://') ||
      url.startsWith('about:') || url.startsWith('edge://') || url.startsWith('moz-extension://')) {
    return;
  }

  try {
    await fetch(SERVER_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url, title }),
    });
  } catch (_) {
    // FocusTrack no está corriendo — ignorar
  }
}

function scheduleReport(url, title) {
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => reportActivity(url, title), DEBOUNCE_MS);
}

// Cambio de pestaña activa
chrome.tabs.onActivated.addListener(async (activeInfo) => {
  try {
    const tab = await chrome.tabs.get(activeInfo.tabId);
    scheduleReport(tab.url, tab.title);
  } catch (_) {}
});

// Actualización de URL en la pestaña activa
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.active) {
    scheduleReport(tab.url, tab.title);
  }
});

// Cambio de ventana activa
chrome.windows?.onFocusChanged?.addListener(async (windowId) => {
  if (windowId === chrome.windows.WINDOW_ID_NONE) return;
  try {
    const [tab] = await chrome.tabs.query({ active: true, windowId });
    if (tab) scheduleReport(tab.url, tab.title);
  } catch (_) {}
});
