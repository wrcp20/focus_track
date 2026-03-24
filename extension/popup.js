const SERVER = 'http://localhost:27432';

const dot = document.getElementById('dot');
const statusText = document.getElementById('statusText');
const currentUrl = document.getElementById('currentUrl');
const sendBtn = document.getElementById('sendBtn');

async function checkStatus() {
  try {
    const res = await fetch(`${SERVER}/status`, { signal: AbortSignal.timeout(2000) });
    if (res.ok) {
      dot.className = 'dot connected';
      statusText.textContent = 'Conectado a FocusTrack';
      return true;
    }
  } catch (_) {}
  dot.className = 'dot disconnected';
  statusText.textContent = 'FocusTrack no está corriendo';
  return false;
}

async function getCurrentTab() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  return tab;
}

async function sendCurrentUrl() {
  const tab = await getCurrentTab();
  if (!tab?.url) return;

  try {
    await fetch(`${SERVER}/activity`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url: tab.url, title: tab.title }),
    });
    statusText.textContent = 'URL enviada ✓';
    setTimeout(() => checkStatus(), 1500);
  } catch (_) {
    statusText.textContent = 'Error al enviar';
  }
}

// Init
(async () => {
  const tab = await getCurrentTab();
  if (tab?.url) {
    currentUrl.textContent = tab.url.length > 60
      ? tab.url.slice(0, 60) + '…'
      : tab.url;
  }
  await checkStatus();
})();

sendBtn.addEventListener('click', sendCurrentUrl);
