import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import gleam/uri.{type Uri}
import icons
import lustre
import lustre/attribute
import lustre/dev/query
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import rsvp
import shared/model.{type Activity}
import youid/uuid

const api_prefix = "/_services/booking"

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Route {
  ActivitiesList
  ActivityNew
  ActivityDetail(id: String)
  NotFound
}

type ActivityForm {
  ActivityForm(
    title: String,
    description: String,
    max_attendees: String,
    start_time: String,
    end_time: String,
  )
}

type Model {
  Model(
    route: Route,
    activities: List(Activity),
    selected_activity: Option(Activity),
    loading: Bool,
    form: ActivityForm,
    editing: Bool,
    error: Option(String),
  )
}

fn empty_form() -> ActivityForm {
  ActivityForm(
    title: "",
    description: "",
    max_attendees: "",
    start_time: "",
    end_time: "",
  )
}

fn form_from_activity(activity: Activity) -> ActivityForm {
  ActivityForm(
    title: activity.title,
    description: activity.description,
    max_attendees: case activity.max_attendees {
      Some(n) -> int.to_string(n)
      None -> ""
    },
    start_time: timestamp_to_datetime_local(activity.start_time),
    end_time: timestamp_to_datetime_local(activity.end_time),
  )
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> uri_to_route(uri)
    Error(_) -> ActivitiesList
  }

  let model =
    Model(
      route:,
      activities: [],
      selected_activity: None,
      loading: True,
      form: empty_form(),
      editing: False,
      error: None,
    )

  let effects = case route {
    ActivitiesList ->
      effect.batch([
        modem.init(OnRouteChange),
        fetch_activities(),
        set_app_bar_title("Activities"),
      ])
    ActivityDetail(id) ->
      effect.batch([modem.init(OnRouteChange), fetch_activity(id)])
    _ -> modem.init(OnRouteChange)
  }

  #(model, effects)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  // Routing
  OnRouteChange(Uri)
  // API responses
  ApiReturnedActivities(Result(List(Activity), rsvp.Error))
  ApiReturnedActivity(Result(Activity, rsvp.Error))
  ApiCreatedActivity(Result(Activity, rsvp.Error))
  ApiUpdatedActivity(Result(Activity, rsvp.Error))
  ApiDeletedActivity(Result(Nil, rsvp.Error))
  // Form field updates
  UserUpdatedTitle(String)
  UserUpdatedDescription(String)
  UserUpdatedMaxAttendees(String)
  UserUpdatedStartTime(String)
  UserUpdatedEndTime(String)
  // User actions
  UserSubmittedCreateForm
  UserSubmittedEditForm
  UserClickedEdit
  UserClickedDelete
  UserClickedCancelEdit
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnRouteChange(uri) -> {
      let route = uri_to_route(uri)
      let model = Model(..model, route:, error: None)
      case route {
        ActivitiesList -> #(
          Model(..model, loading: True, editing: False),
          effect.batch([fetch_activities(), set_app_bar_title("Activities")]),
        )
        ActivityDetail(id) -> #(
          Model(..model, loading: True, selected_activity: None, editing: False),
          fetch_activity(id),
        )
        ActivityNew -> #(
          Model(..model, form: empty_form(), editing: False),
          effect.none(),
        )
        NotFound -> #(model, effect.none())
      }
    }

    ApiReturnedActivities(Ok(activities)) -> #(
      Model(..model, activities:, loading: False),
      effect.none(),
    )

    ApiReturnedActivities(Error(_)) -> #(
      Model(..model, loading: False, error: Some("Failed to load activities")),
      effect.none(),
    )

    ApiReturnedActivity(Ok(activity)) -> #(
      Model(
        ..model,
        selected_activity: Some(activity),
        form: form_from_activity(activity),
        loading: False,
      ),
      effect.none(),
    )

    ApiReturnedActivity(Error(_)) -> #(
      Model(..model, loading: False, error: Some("Failed to load activity")),
      effect.none(),
    )

    ApiCreatedActivity(Ok(_)) -> #(
      model,
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiCreatedActivity(Error(_)) -> #(
      Model(..model, error: Some("Failed to create activity")),
      effect.none(),
    )

    ApiUpdatedActivity(Ok(activity)) -> #(
      Model(
        ..model,
        selected_activity: Some(activity),
        form: form_from_activity(activity),
        editing: False,
        error: None,
      ),
      effect.none(),
    )

    ApiUpdatedActivity(Error(_)) -> #(
      Model(..model, error: Some("Failed to update activity")),
      effect.none(),
    )

    ApiDeletedActivity(Ok(_)) -> #(
      model,
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiDeletedActivity(Error(_)) -> #(
      Model(..model, error: Some("Failed to delete activity")),
      effect.none(),
    )

    UserUpdatedTitle(value) -> #(
      Model(..model, form: ActivityForm(..model.form, title: value)),
      effect.none(),
    )

    UserUpdatedDescription(value) -> #(
      Model(..model, form: ActivityForm(..model.form, description: value)),
      effect.none(),
    )

    UserUpdatedMaxAttendees(value) -> #(
      Model(..model, form: ActivityForm(..model.form, max_attendees: value)),
      effect.none(),
    )

    UserUpdatedStartTime(value) -> #(
      Model(..model, form: ActivityForm(..model.form, start_time: value)),
      effect.none(),
    )

    UserUpdatedEndTime(value) -> #(
      Model(..model, form: ActivityForm(..model.form, end_time: value)),
      effect.none(),
    )

    UserSubmittedCreateForm -> #(model, create_activity(model.form))

    UserSubmittedEditForm ->
      case model.selected_activity {
        Some(activity) -> #(
          model,
          update_activity(uuid.to_string(activity.id), model.form),
        )
        None -> #(model, effect.none())
      }

    UserClickedEdit -> #(Model(..model, editing: True), effect.none())

    UserClickedCancelEdit ->
      case model.selected_activity {
        Some(activity) -> #(
          Model(..model, editing: False, form: form_from_activity(activity)),
          effect.none(),
        )
        None -> #(Model(..model, editing: False), effect.none())
      }

    UserClickedDelete ->
      case model.selected_activity {
        Some(activity) -> #(model, delete_activity(uuid.to_string(activity.id)))
        None -> #(model, effect.none())
      }
  }
}

// EFFECTS ---------------------------------------------------------------------

@external(javascript, "./client_ffi.mjs", "post_message_to_parent")
fn post_message_to_parent(type_: String, title: String) -> Nil

pub fn set_app_bar_title(title: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { post_message_to_parent("j26:appBar", title) })
}

fn fetch_activities() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activities",
    rsvp.expect_json(model.activities_decoder(), ApiReturnedActivities),
  )
}

fn fetch_activity(id: String) -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activities/" <> id,
    rsvp.expect_json(model.activity_decoder(), ApiReturnedActivity),
  )
}

fn create_activity(form: ActivityForm) -> Effect(Msg) {
  let body = form_to_json(form)
  rsvp.post(
    api_prefix <> "/api/activities",
    body,
    rsvp.expect_json(model.activity_decoder(), ApiCreatedActivity),
  )
}

fn update_activity(id: String, form: ActivityForm) -> Effect(Msg) {
  let body = form_to_json(form)
  rsvp.put(
    api_prefix <> "/api/activities/" <> id,
    body,
    rsvp.expect_json(model.activity_decoder(), ApiUpdatedActivity),
  )
}

fn delete_activity(id: String) -> Effect(Msg) {
  rsvp.delete(
    api_prefix <> "/api/activities/" <> id,
    json.null(),
    rsvp.expect_any_response(fn(result) {
      case result {
        Ok(_) -> ApiDeletedActivity(Ok(Nil))
        Error(err) -> ApiDeletedActivity(Error(err))
      }
    }),
  )
}

fn form_to_json(form: ActivityForm) -> json.Json {
  let max_attendees = case int.parse(form.max_attendees) {
    Ok(n) -> json.int(n)
    Error(_) -> json.null()
  }
  let start_secs = datetime_local_to_unix_seconds(form.start_time)
  let end_secs = datetime_local_to_unix_seconds(form.end_time)

  json.object([
    #("title", json.string(form.title)),
    #("description", json.string(form.description)),
    #("max_attendees", max_attendees),
    #("start_time", json.int(start_secs)),
    #("end_time", json.int(end_secs)),
  ])
}

// ROUTING ---------------------------------------------------------------------

fn uri_to_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) |> list.drop(2) {
    ["activities"] -> ActivitiesList
    ["activities", "new"] -> ActivityNew
    ["activities", id] -> ActivityDetail(id)
    [] -> ActivitiesList
    _ -> NotFound
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.route {
    ActivitiesList -> view_activities_list(model)
    ActivityNew -> view_activity_new(model)
    ActivityDetail(_) -> view_activity_detail(model)
    NotFound -> view_not_found()
  }
}

fn view_activities_list(model: Model) -> Element(Msg) {
  scout_stack("column", "none", [
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("justify-content", "space-between"),
          #("align-items", "center"),
          #("padding", "var(--scout-spacing-m)"),
        ]),
      ],
      [
        html.a(
          [
            attribute.href(api_prefix <> "/activities/new"),
            attribute.styles([#("text-decoration", "none")]),
          ],
          [scout_button_icon("Create", "primary", "plus")],
        ),
      ],
    ),
    case model.error {
      Some(err) -> error_banner(err)
      None -> element.none()
    },
    case model.loading {
      True ->
        html.div([attribute.styles([#("padding", "var(--scout-spacing-l)")])], [
          scout_loader("Loading activities..."),
        ])
      False ->
        case list.is_empty(model.activities) {
          True ->
            html.div(
              [
                attribute.styles([
                  #("padding", "var(--scout-spacing-l)"),
                  #("text-align", "center"),
                ]),
              ],
              [
                html.p([], [element.text("No activities yet.")]),
                html.a(
                  [
                    attribute.href(api_prefix <> "/activities/new"),
                    attribute.styles([#("text-decoration", "none")]),
                  ],
                  [scout_button_el("Create first activity", "primary")],
                ),
              ],
            )
          False ->
            element.element("scout-list-view", [], {
              use activity <- list.map(model.activities)
              let id = uuid.to_string(activity.id)
              let secondary =
                format_time_range(activity.start_time, activity.end_time)
              element.element(
                "scout-list-view-item",
                [
                  attribute.attribute("type", "link"),
                  attribute.attribute("primary", activity.title),
                  attribute.attribute("secondary", secondary),
                  attribute.href(api_prefix <> "/activities/" <> id),
                ],
                [],
              )
            })
        }
    },
  ])
}

fn view_activity_new(model: Model) -> Element(Msg) {
  scout_stack("column", "none", [
    html.div([attribute.styles([#("padding", "var(--scout-spacing-m)")])], [
      html.h1([], [element.text("New Activity")]),
    ]),
    html.div([attribute.styles([#("padding", "var(--scout-spacing-m)")])], [
      case model.error {
        Some(err) -> error_banner(err)
        None -> element.none()
      },
      scout_card([
        scout_stack("column", "m", [
          scout_field(
            "Title",
            scout_input("text", model.form.title, UserUpdatedTitle),
          ),
          scout_field(
            "Description",
            scout_input("text", model.form.description, UserUpdatedDescription),
          ),
          scout_field(
            "Max attendees",
            scout_input(
              "number",
              model.form.max_attendees,
              UserUpdatedMaxAttendees,
            ),
          ),
          scout_field(
            "Start time",
            scout_input(
              "datetime-local",
              model.form.start_time,
              UserUpdatedStartTime,
            ),
          ),
          scout_field(
            "End time",
            scout_input(
              "datetime-local",
              model.form.end_time,
              UserUpdatedEndTime,
            ),
          ),
          scout_button_action("Create", "primary", UserSubmittedCreateForm),
        ]),
      ]),
    ]),
  ])
}

fn view_activity_detail(model: Model) -> Element(Msg) {
  case model.loading {
    True ->
      html.div([attribute.class("flex justify-center py-8")], [
        scout_loader("Laddar aktivitet..."),
      ])
    False ->
      case model.selected_activity {
        None ->
          scout_stack("column", "none", [
            html.div(
              [
                attribute.styles([
                  #("display", "flex"),
                  #("align-items", "center"),
                  #("gap", "var(--scout-spacing-s)"),
                  #("padding", "var(--scout-spacing-m)"),
                ]),
              ],
              [
                html.h1([], [element.text("Not Found")]),
              ],
            ),
            html.div(
              [attribute.styles([#("padding", "var(--scout-spacing-l)")])],
              [html.p([], [element.text("Activity not found.")])],
            ),
          ])
        Some(activity) -> view_activity_detail_loaded(model, activity)
      }
  }
}

fn view_activity_detail_loaded(model: Model, activity: Activity) -> Element(Msg) {
  html.div([attribute.class("flex flex-col")], [
    html.div(
      // Map
      [
        attribute.class("sticky top-0 h-28"),
      ],
      [
        html.iframe([
          attribute.src(
            // TODO: Use proper coordinates.
            "/_services/map/preview.html?lat=55.979571&lng=14.130669&icon=badge-wc&variant=filled",
          ),
          attribute.class("w-full h-full outline-none pointer-events-none"),
          attribute.loading("lazy"),
        ]),
      ],
    ),
    html.div(
      // Content
      [
        attribute.class(
          "z-10 bg-white border-t border-gray-200 flex-1 flex flex-col p-4 gap-4",
        ),
      ],
      [
        html.div(
          // Header row
          [
            attribute.class("flex gap-4"),
          ],
          [
            html.div([attribute.class("flex-1 flex pt-1")], [
              html.h1(
                [
                  attribute.class("text-heading-xs"),
                ],
                [element.text(activity.title)],
              ),
            ]),
            html.div([attribute.class("flex flex-col gap-1 items-end")], [
              scout_button_action("Boka", "primary", UserClickedEdit),
              html.div(
                [
                  attribute.class(
                    "flex gap-2 items-center text-body-sm text-gray-500",
                  ),
                ],
                [
                  element.unsafe_raw_html(
                    "",
                    "div",
                    [attribute.class("size-4")],
                    icons.users,
                  ),
                  html.p(
                    [
                      attribute.class("flex-1"),
                    ],
                    [element.text("17 platser kvar")],
                  ),
                  // TODO: Calculate remaining spots based on attendees
                ],
              ),
            ]),
          ],
        ),
        html.div(
          [
            // Quick info
            attribute.class("flex-1 grid grid-cols-2"),
          ],
          [
            quick_info_tile(icons.clock, "Tid", [
              // TODO: What about activities that span multiple days? What
              // about activities that are tomorrow? Next week?
              element.text(format_time_range(
                activity.start_time,
                activity.end_time,
              )),
            ]),
            quick_info_tile(icons.pin, "Plats", [
              element.text("Badbusstorget"),
              // TODO: Mocked data
            ]),
          ],
        ),
        html.div([], [
          html.p([attribute.class("text-body-m")], [
            element.text(activity.description),
            html.br([]),
            html.br([]),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
            element.text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            ),
          ]),
        ]),
      ],
    ),
  ])
  // scout_stack("column", "none", [
  //   html.div([attribute.styles([#("padding", "var(--scout-spacing-m)")])], [
  //     html.h1([], [element.text(activity.title)]),
  //   ]),
  //   html.div([attribute.styles([#("padding", "var(--scout-spacing-m)")])], [
  //     case model.error {
  //       Some(err) -> error_banner(err)
  //       None -> element.none()
  //     },
  //     scout_card([
  //       case model.editing {
  //         False -> view_activity_read_only(activity)
  //         True -> view_activity_edit_form(model)
  //       },
  //     ]),
  //     html.div(
  //       [
  //         attribute.styles([
  //           #("padding-top", "var(--scout-spacing-m)"),
  //           #("display", "flex"),
  //           #("gap", "var(--scout-spacing-s)"),
  //         ]),
  //       ],
  //       case model.editing {
  //         False -> [
  //           scout_button_action("Edit", "outlined", UserClickedEdit),
  //           scout_button_action("Delete", "danger", UserClickedDelete),
  //         ]
  //         True -> [
  //           scout_button_action("Save", "primary", UserSubmittedEditForm),
  //           scout_button_action("Cancel", "outlined", UserClickedCancelEdit),
  //         ]
  //       },
  //     ),
  //   ]),
  // ])
}

fn quick_info_tile(
  icon: String,
  title: String,
  content: List(Element(Msg)),
) -> Element(Msg) {
  html.div([attribute.class("flex flex-col")], [
    html.div([attribute.class("flex items-center gap-1 text-gray-800")], [
      component_icon(icon, "size-4"),
      html.div([attribute.class("text-body-sm")], [
        element.text(title),
      ]),
    ]),
    html.div([], content),
  ])
}

fn component_icon(icon: String, class: String) -> Element(Msg) {
  element.unsafe_raw_html("", "div", [attribute.class(class)], icon)
}

fn view_activity_read_only(activity: Activity) -> Element(Msg) {
  scout_stack("column", "m", [
    detail_row("Description", activity.description),
    detail_row("Max attendees", case activity.max_attendees {
      Some(n) -> int.to_string(n)
      None -> "No limit"
    }),
    detail_row("Start time", timestamp_to_time(activity.start_time)),
    detail_row("End time", timestamp_to_time(activity.end_time)),
  ])
}

fn detail_row(label: String, value: String) -> Element(Msg) {
  scout_stack("column", "xs", [
    html.strong([], [element.text(label)]),
    html.p([attribute.styles([#("margin", "0")])], [element.text(value)]),
  ])
}

fn view_activity_edit_form(model: Model) -> Element(Msg) {
  scout_stack("column", "m", [
    scout_field(
      "Title",
      scout_input("text", model.form.title, UserUpdatedTitle),
    ),
    scout_field(
      "Description",
      scout_input("text", model.form.description, UserUpdatedDescription),
    ),
    scout_field(
      "Max attendees",
      scout_input("number", model.form.max_attendees, UserUpdatedMaxAttendees),
    ),
    scout_field(
      "Start time",
      scout_input("datetime-local", model.form.start_time, UserUpdatedStartTime),
    ),
    scout_field(
      "End time",
      scout_input("datetime-local", model.form.end_time, UserUpdatedEndTime),
    ),
  ])
}

fn view_not_found() -> Element(Msg) {
  scout_stack("column", "none", [
    html.div([attribute.styles([#("padding", "var(--scout-spacing-m)")])], [
      html.h1([], [element.text("Not Found")]),
    ]),
    html.div([attribute.styles([#("padding", "var(--scout-spacing-l)")])], [
      html.p([], [element.text("Page not found.")]),
      html.a([attribute.href(api_prefix <> "/activities")], [
        element.text("Go to activities"),
      ]),
    ]),
  ])
}

// COMPONENT WRAPPERS ----------------------------------------------------------

fn scout_stack(
  direction: String,
  gap: String,
  children: List(Element(Msg)),
) -> Element(Msg) {
  element.element(
    "scout-stack",
    [
      attribute.attribute("direction", direction),
      attribute.attribute("gap-size", gap),
    ],
    children,
  )
}

fn scout_card(children: List(Element(Msg))) -> Element(Msg) {
  element.element("scout-card", [], children)
}

fn scout_field(label: String, child: Element(Msg)) -> Element(Msg) {
  element.element("scout-field", [attribute.attribute("label", label)], [child])
}

fn scout_input(
  input_type: String,
  value: String,
  on_input: fn(String) -> Msg,
) -> Element(Msg) {
  element.element(
    "scout-input",
    [
      attribute.attribute("type", input_type),
      attribute.attribute("value", value),
      event.on_input(on_input),
    ],
    [],
  )
}

fn scout_button_action(text: String, variant: String, msg: Msg) -> Element(Msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      event.on("scoutClick", decode.success(msg)),
    ],
    [element.text(text)],
  )
}

fn scout_button_el(text: String, variant: String) -> Element(Msg) {
  element.element("scout-button", [attribute.attribute("variant", variant)], [
    element.text(text),
  ])
}

fn scout_button_icon(
  text: String,
  variant: String,
  icon: String,
) -> Element(Msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      attribute.attribute("icon", icon),
      attribute.attribute("icon-only", ""),
      attribute.attribute("aria-label", text),
    ],
    [],
  )
}

fn scout_loader(text: String) -> Element(Msg) {
  element.element(
    "scout-loader",
    [
      attribute.attribute("text", text),
      attribute.attribute("size", "base"),
    ],
    [],
  )
}

fn error_banner(message: String) -> Element(Msg) {
  html.div(
    [
      attribute.styles([
        #("padding", "var(--scout-spacing-s) var(--scout-spacing-m)"),
        #("background", "var(--scout-color-danger-100, #fee)"),
        #("color", "var(--scout-color-danger-700, #c00)"),
        #("border-radius", "var(--scout-radius-s, 4px)"),
      ]),
    ],
    [element.text(message)],
  )
}

// HELPERS ---------------------------------------------------------------------

/// Format a Timestamp as "YYYY-MM-DDTHH:MM" for datetime-local inputs.
fn timestamp_to_datetime_local(ts: timestamp.Timestamp) -> String {
  let #(date, time) = timestamp.to_calendar(ts, calendar.local_offset())
  let year = int.to_string(date.year)
  let month = date.month |> calendar.month_to_int |> pad2
  let day = pad2(date.day)
  let hours = pad2(time.hours)
  let minutes = pad2(time.minutes)
  year <> "-" <> month <> "-" <> day <> "T" <> hours <> ":" <> minutes
}

/// Format a Timestamp as "HH:MM"
fn timestamp_to_time(ts: timestamp.Timestamp) -> String {
  let #(_, time) = timestamp.to_calendar(ts, calendar.local_offset())
  let hours = pad2(time.hours)
  let minutes = pad2(time.minutes)
  hours <> ":" <> minutes
}

/// Parse a "YYYY-MM-DDTHH:MM" datetime-local value to unix seconds.
fn datetime_local_to_unix_seconds(value: String) -> Int {
  // datetime-local format: YYYY-MM-DDTHH:MM
  // Append ":00" for seconds and local offset to make it RFC 3339 parseable
  let rfc3339 = value <> ":00" <> local_offset_string()
  case timestamp.parse_rfc3339(rfc3339) {
    Ok(ts) -> {
      let #(secs, _nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
      secs
    }
    Error(_) -> 0
  }
}

/// Get the local UTC offset as a string like "+02:00" or "-05:00".
fn local_offset_string() -> String {
  let offset = calendar.local_offset()
  let total_seconds = {
    let #(secs, _nanos) =
      timestamp.to_unix_seconds_and_nanoseconds(timestamp.add(
        timestamp.unix_epoch,
        offset,
      ))
    secs
  }
  let sign = case total_seconds >= 0 {
    True -> "+"
    False -> "-"
  }
  let abs_seconds = int.absolute_value(total_seconds)
  let hours = abs_seconds / 3600
  let minutes = { abs_seconds % 3600 } / 60
  sign <> pad2(hours) <> ":" <> pad2(minutes)
}

fn pad2(n: Int) -> String {
  let s = int.to_string(n)
  case string.length(s) {
    1 -> "0" <> s
    _ -> s
  }
}

fn format_time_range(
  start: timestamp.Timestamp,
  end: timestamp.Timestamp,
) -> String {
  timestamp_to_time(start) <> " – " <> timestamp_to_time(end)
}
