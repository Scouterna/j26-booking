import formal/form.{type Form}
import g18n.{type Translator}
import g18n/locale
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
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import rsvp
import shared/model.{type Activity}
import youid/uuid

const api_prefix = "/_services/booking"

// TRANSLATIONS ----------------------------------------------------------------

fn english_translations() -> g18n.Translations {
  g18n.new_translations()
  |> g18n.add_translation("activity.loading", "Loading activity...")
  |> g18n.add_translation("activity.not_found_title", "Not Found")
  |> g18n.add_translation("activity.not_found_message", "Activity not found.")
  |> g18n.add_translation("activity.book", "Book")
  |> g18n.add_translation("activity.spots_remaining", "17 spots remaining")
  |> g18n.add_translation("activity.time", "Time")
  |> g18n.add_translation("activity.date_range_separator", "to")
  |> g18n.add_translation("activity.location", "Location")
  |> g18n.add_translation("app_bar.activities_list", "Activities")
  |> g18n.add_translation("app_bar.activity_detail", "Activity")
  |> g18n.add_translation("app_bar.activity_new", "Create activity")
}

fn swedish_translations() -> g18n.Translations {
  g18n.new_translations()
  |> g18n.add_translation("activity.loading", "Laddar aktivitet...")
  |> g18n.add_translation("activity.not_found_title", "Hittades inte")
  |> g18n.add_translation(
    "activity.not_found_message",
    "Aktiviteten hittades inte.",
  )
  |> g18n.add_translation("activity.book", "Boka")
  |> g18n.add_translation("activity.spots_remaining", "17 platser kvar")
  |> g18n.add_translation("activity.time", "Tid")
  |> g18n.add_translation("activity.date_range_separator", "till")
  |> g18n.add_translation("activity.location", "Plats")
  |> g18n.add_translation("app_bar.activities_list", "Spontanaktiviteter")
  |> g18n.add_translation("app_bar.activity_detail", "Aktivitet")
  |> g18n.add_translation("app_bar.activity_new", "Skapa aktivitet")
}

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
  ActivityEdit(id: String)
  NotFound
}

type ActivityForm {
  ActivityForm(
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: #(calendar.Date, calendar.TimeOfDay),
    end_time: #(calendar.Date, calendar.TimeOfDay),
  )
}

type Model {
  Model(
    route: Route,
    activities: List(Activity),
    selected_activity: Option(Activity),
    loading: Bool,
    form: Form(ActivityForm),
    error: Option(String),
    translator: Translator,
  )
}

fn activity_form() -> Form(ActivityForm) {
  form.new({
    use title <- form.field("title", form.parse_string |> form.check_not_empty)
    use description <- form.field("description", form.parse_string)
    use max_attendees <- form.field(
      "max_attendees",
      form.parse_optional(form.parse_int),
    )
    use start_time <- form.field("start_time", form.parse_date_time)
    use end_time <- form.field("end_time", form.parse_date_time)
    form.success(ActivityForm(
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
    ))
  })
}

fn form_from_activity(activity: Activity) -> Form(ActivityForm) {
  activity_form()
  |> form.add_string("title", activity.title)
  |> form.add_string("description", activity.description)
  |> form.add_string("max_attendees", case activity.max_attendees {
    Some(n) -> int.to_string(n)
    None -> ""
  })
  |> form.add_string(
    "start_time",
    timestamp_to_datetime_local(activity.start_time),
  )
  |> form.add_string("end_time", timestamp_to_datetime_local(activity.end_time))
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> uri_to_route(uri)
    Error(_) -> ActivitiesList
  }

  let assert Ok(locale) = locale.new("sv")
  let translations = swedish_translations()
  let translator = g18n.new_translator(locale, translations)

  let model =
    Model(
      route:,
      activities: [],
      selected_activity: None,
      loading: True,
      form: activity_form(),
      error: None,
      translator: translator,
    )

  let effects = case route {
    ActivitiesList ->
      effect.batch([
        modem.init(OnRouteChange),
        fetch_activities(),
        set_app_bar_title(g18n.translate(translator, "app_bar.activities_list")),
      ])
    ActivityDetail(id) ->
      effect.batch([
        modem.init(OnRouteChange),
        fetch_activity(id),
        set_app_bar_title(g18n.translate(translator, "app_bar.activity_detail")),
      ])
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
  // Form submissions
  UserSubmittedCreateForm(Result(ActivityForm, Form(ActivityForm)))
  UserSubmittedEditForm(Result(ActivityForm, Form(ActivityForm)))
  // User actions
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
          Model(..model, loading: True),
          effect.batch([
            fetch_activities(),
            set_app_bar_title(g18n.translate(
              model.translator,
              "app_bar.activities_list",
            )),
          ]),
        )
        ActivityDetail(id) -> #(
          Model(..model, loading: True, selected_activity: None),
          effect.batch([
            fetch_activity(id),
            set_app_bar_title(g18n.translate(
              model.translator,
              "app_bar.activity_detail",
            )),
          ]),
        )
        ActivityNew -> #(
          Model(..model, form: activity_form()),
          set_app_bar_title(g18n.translate(
            model.translator,
            "app_bar.activity_new",
          )),
        )
        ActivityEdit(id) -> todo
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

    UserSubmittedCreateForm(Ok(activity_form)) -> #(
      model,
      create_activity(activity_form),
    )

    UserSubmittedCreateForm(Error(f)) -> #(
      Model(..model, form: f),
      effect.none(),
    )

    UserSubmittedEditForm(Ok(activity_form)) ->
      case model.selected_activity {
        Some(activity) -> #(
          model,
          update_activity(uuid.to_string(activity.id), activity_form),
        )
        None -> #(model, effect.none())
      }

    UserSubmittedEditForm(Error(f)) -> #(Model(..model, form: f), effect.none())

    UserClickedEdit -> #(model, effect.none())

    UserClickedCancelEdit ->
      case model.selected_activity {
        Some(activity) -> #(
          Model(..model, form: form_from_activity(activity)),
          effect.none(),
        )
        None -> #(model, effect.none())
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

fn set_app_bar_title(title: String) -> Effect(msg) {
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

fn create_activity(af: ActivityForm) -> Effect(Msg) {
  rsvp.post(
    api_prefix <> "/api/activities",
    activity_form_to_json(af),
    rsvp.expect_json(model.activity_decoder(), ApiCreatedActivity),
  )
}

fn update_activity(id: String, af: ActivityForm) -> Effect(Msg) {
  rsvp.put(
    api_prefix <> "/api/activities/" <> id,
    activity_form_to_json(af),
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

fn activity_form_to_json(af: ActivityForm) -> json.Json {
  let to_secs = fn(dt: #(calendar.Date, calendar.TimeOfDay)) -> Int {
    let ts =
      timestamp.from_calendar(
        date: dt.0,
        time: dt.1,
        offset: calendar.local_offset(),
      )
    let #(secs, _) = timestamp.to_unix_seconds_and_nanoseconds(ts)
    secs
  }
  json.object([
    #("title", json.string(af.title)),
    #("description", json.string(af.description)),
    #("max_attendees", case af.max_attendees {
      Some(n) -> json.int(n)
      None -> json.null()
    }),
    #("start_time", json.int(to_secs(af.start_time))),
    #("end_time", json.int(to_secs(af.end_time))),
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
    ActivityEdit(id) -> todo
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
  let submitted = fn(values) {
    model.form
    |> form.add_values(values)
    |> form.run
    |> UserSubmittedCreateForm
  }
  scout_stack("column", "none", [
    html.div([attribute.styles([#("padding", "var(--scout-spacing-m)")])], [
      html.h1([], [element.text("New Activity")]),
    ]),
    html.div([attribute.styles([#("padding", "var(--scout-spacing-m)")])], [
      case model.error {
        Some(err) -> error_banner(err)
        None -> element.none()
      },
      html.form([event.on_submit(submitted)], [
        scout_card([
          scout_stack("column", "m", [
            scout_form_field(model.form, "Title", "text", "title"),
            scout_form_field(model.form, "Description", "text", "description"),
            scout_form_field(
              model.form,
              "Max attendees",
              "number",
              "max_attendees",
            ),
            scout_form_field(
              model.form,
              "Start time",
              "datetime-local",
              "start_time",
            ),
            scout_form_field(
              model.form,
              "End time",
              "datetime-local",
              "end_time",
            ),
            element.element(
              "scout-button",
              [
                attribute.attribute("variant", "primary"),
                attribute.attribute("type", "submit"),
              ],
              [element.text("Create")],
            ),
          ]),
        ]),
      ]),
    ]),
  ])
}

fn view_activity_detail(model: Model) -> Element(Msg) {
  case model.loading {
    True ->
      html.div([attribute.class("flex justify-center py-8")], [
        scout_loader(g18n.translate(model.translator, "activity.loading")),
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
                html.h1([], [
                  element.text(g18n.translate(
                    model.translator,
                    "activity.not_found_title",
                  )),
                ]),
              ],
            ),
            html.div(
              [attribute.styles([#("padding", "var(--scout-spacing-l)")])],
              [
                html.p([], [
                  element.text(g18n.translate(
                    model.translator,
                    "activity.not_found_message",
                  )),
                ]),
              ],
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
              scout_button_action(
                g18n.translate(model.translator, "activity.book"),
                "primary",
                UserClickedEdit,
              ),
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
                    [
                      element.text(g18n.translate(
                        model.translator,
                        "activity.spots_remaining",
                      )),
                    ],
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
            quick_info_tile(
              icons.clock,
              g18n.translate(model.translator, "activity.time"),
              [
                view_time_interval(
                  model,
                  activity.start_time,
                  activity.end_time,
                ),
              ],
            ),
            quick_info_tile(
              icons.pin,
              g18n.translate(model.translator, "activity.location"),
              [
                element.text("Badbusstorget"),
                // TODO: Mocked data
              ],
            ),
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

type IntervalClasses {
  SameDayDifferentTime
  SameDaySameTime
  DifferentDays
}

fn classify_interval(
  start_calendar: #(calendar.Date, calendar.TimeOfDay),
  end_calendar: #(calendar.Date, calendar.TimeOfDay),
) -> IntervalClasses {
  let #(start_date, start_time) = start_calendar
  let #(end_date, end_time) = end_calendar
  let same_day = start_date == end_date
  let same_time = start_time == end_time
  case same_day, same_time {
    True, True -> SameDaySameTime
    True, False -> SameDayDifferentTime
    _, _ -> DifferentDays
  }
}

fn view_time_interval(
  model: Model,
  start: timestamp.Timestamp,
  end: timestamp.Timestamp,
) -> Element(Msg) {
  let start_calendar = timestamp.to_calendar(start, calendar.utc_offset)
  let end_calendar = timestamp.to_calendar(end, calendar.utc_offset)
  let translator = model.translator
  let format_date = fn(d) {
    g18n.format_date(translator, d, g18n.Custom("EEEE d/M"))
  }
  let format_time = fn(tod) {
    g18n.format_time(translator, tod, g18n.Custom("HH.mm"))
  }
  case classify_interval(start_calendar, end_calendar) {
    SameDayDifferentTime ->
      html.span([], [
        element.text(format_date(start_calendar.0)),
        html.br([]),
        element.text(
          format_time(start_calendar.1) <> " - " <> format_time(end_calendar.1),
        ),
      ])
    SameDaySameTime ->
      html.span([], [
        element.text(format_date(start_calendar.0)),
        html.br([]),
        element.text(format_time(start_calendar.1)),
      ])
    DifferentDays -> {
      let separator =
        g18n.translate(model.translator, "activity.date_range_separator")
      html.span([], [
        element.text(format_date(start_calendar.0)),
        html.br([]),
        element.text(format_time(start_calendar.1) <> " " <> separator),
        html.br([]),
        element.text(format_date(end_calendar.0)),
        html.br([]),
        element.text(format_time(end_calendar.1)),
      ])
    }
  }
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
  let submitted = fn(values) {
    model.form
    |> form.add_values(values)
    |> form.run
    |> UserSubmittedEditForm
  }
  html.form([event.on_submit(submitted)], [
    scout_stack("column", "m", [
      scout_form_field(model.form, "Title", "text", "title"),
      scout_form_field(model.form, "Description", "text", "description"),
      scout_form_field(model.form, "Max attendees", "number", "max_attendees"),
      scout_form_field(model.form, "Start time", "datetime-local", "start_time"),
      scout_form_field(model.form, "End time", "datetime-local", "end_time"),
      element.element(
        "scout-button",
        [
          attribute.attribute("variant", "primary"),
          attribute.attribute("type", "submit"),
        ],
        [element.text("Save")],
      ),
    ]),
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

fn scout_form_field(
  f: Form(a),
  label: String,
  input_type: String,
  name: String,
) -> Element(Msg) {
  let errors = form.field_error_messages(f, name)
  scout_field(
    label,
    element.fragment([
      element.element(
        "scout-input",
        [
          attribute.attribute("type", input_type),
          attribute.attribute("name", name),
          attribute.attribute("value", form.field_value(f, name)),
        ],
        [],
      ),
      ..list.map(errors, fn(msg) {
        html.small(
          [
            attribute.styles([
              #("color", "var(--scout-color-danger-700, #c00)"),
            ]),
          ],
          [element.text(msg)],
        )
      })
    ]),
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
