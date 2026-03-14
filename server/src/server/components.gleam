import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn spa_shell_page(base_path: String) -> Element(a) {
  html.html([attribute.attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.content("width=device-width, initial-scale=1"),
        attribute.name("viewport"),
      ]),
      html.title([], "Jamboree 2026 Booking"),
      html.script(
        [
          attribute.src(
            "https://cdn.jsdelivr.net/npm/@scouterna/ui-webc@3.2.0/dist/esm/ui-webc.js",
          ),
          attribute.type_("module"),
        ],
        "",
      ),
      html.script(
        [
          attribute.type_("module"),
          attribute.src(base_path <> "/static/client.js"),
        ],
        "",
      ),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(
          "https://cdn.jsdelivr.net/npm/@scouterna/ui-webc@3.2.0/dist/ui-webc/ui-webc.css",
        ),
      ]),
      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.googleapis.com"),
      ]),
      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.gstatic.com"),
        attribute.attribute("crossorigin", ""),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(
          "https://fonts.googleapis.com/css2?family=Source+Sans+3:ital,wght@0,200..900;1,200..900&display=swap",
        ),
      ]),
    ]),
    html.body(
      [
        attribute.styles([
          #("margin", "0"),
          #("font-family", "Source Sans 3, sans-serif"),
        ]),
      ],
      [html.div([attribute.id("app")], [])],
    ),
  ])
}

pub fn api_documentation_page() -> Element(a) {
  html.html([], [
    html.head([], [
      html.title([], "J26 Booking API Documentation"),
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.content("width=device-width, initial-scale=1"),
        attribute.name("viewport"),
      ]),
    ]),
    html.body([], [
      html.div([attribute.id("app")], []),
      html.script(
        [attribute.src("https://cdn.jsdelivr.net/npm/@scalar/api-reference")],
        "",
      ),
      html.script(
        [],
        "Scalar.createApiReference('#app', {url: '/static/openapi.yaml'})",
      ),
    ]),
  ])
}
