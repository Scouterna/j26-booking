export function post_app_bar_title(title) {
  window.parent.postMessage(
    { type: "j26:appBar", title },
    window.location.origin,
  );
}

export function post_navigation(url) {
  window.parent.postMessage(
    { type: "j26:navigate", url },
    window.location.origin,
  );
}

function html_element() {
  return window.parent !== window
    ? window.parent.document.documentElement
    : document.documentElement;
}

export function get_html_lang() {
  return html_element().lang || "";
}

export function observe_html_lang(callback) {
  const html = html_element();
  const observer = new MutationObserver(() => {
    callback(html.lang || "");
  });
  observer.observe(html, { attributes: true, attributeFilter: ["lang"] });
  window.addEventListener("pagehide", () => observer.disconnect(), {
    once: true,
  });
}

// Fire `callback` every `ms` milliseconds. Used by the booking-overview pages
// to auto-refresh once a minute so they can be left open on a display. The
// interval is cleared on pagehide so it doesn't outlive the document.
export function set_interval(ms, callback) {
  const id = window.setInterval(callback, ms);
  window.addEventListener("pagehide", () => window.clearInterval(id), {
    once: true,
  });
}
