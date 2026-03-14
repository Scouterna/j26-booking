export function post_message_to_parent(type, title) {
  window.parent.postMessage({ type, title }, window.location.origin);
}
