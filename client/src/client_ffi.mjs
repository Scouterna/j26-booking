export function post_message_to_parent(type, title) {
  window.parent.postMessage({ type, title }, window.location.origin);
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
