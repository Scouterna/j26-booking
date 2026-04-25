import component
import formal/form.{type Form}
import g18n.{type Translator}
import g18n/locale
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
  |> g18n.add_translation(
    "activity.spots_remaining.one",
    "{count} spot remaining",
  )
  |> g18n.add_translation(
    "activity.spots_remaining.other",
    "{count} spots remaining",
  )
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
  |> g18n.add_translation("activity.spots_remaining.one", "{count} plats kvar")
  |> g18n.add_translation(
    "activity.spots_remaining.other",
    "{count} platser kvar",
  )
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

type ActivityForm {
  ActivityForm(
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: #(calendar.Date, calendar.TimeOfDay),
    end_time: #(calendar.Date, calendar.TimeOfDay),
  )
}

type RemoteData(a) {
  Loading
  Loaded(a)
  Failed(String)
}

type EditState {
  EditLoading
  EditReady(
    activity: Activity,
    form: Form(ActivityForm),
    submit_error: Option(String),
  )
  EditLoadFailed(String)
}

type Page {
  ActivitiesListPage(state: RemoteData(List(Activity)))
  ActivityNewPage(form: Form(ActivityForm), submit_error: Option(String))
  ActivityDetailPage(id: String, state: RemoteData(Activity))
  ActivityEditPage(id: String, state: EditState)
  NotFoundPage
}

type Model {
  Model(page: Page, translator: Translator)
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
    timestamp.to_rfc3339(activity.start_time, calendar.local_offset())
      |> string.slice(0, 16),
  )
  |> form.add_string(
    "end_time",
    timestamp.to_rfc3339(activity.end_time, calendar.local_offset())
      |> string.slice(0, 16),
  )
}

fn translator_for(lang: String) -> Translator {
  let assert Ok(en) = locale.new("en")
  let assert Ok(sv) = locale.new("sv")
  let preferred = case locale.new(lang) {
    Ok(l) -> [l]
    Error(_) -> []
  }
  let chosen = case locale.negotiate_locale([en, sv], preferred) {
    Ok(l) -> l
    Error(_) -> sv
  }
  let translations = case locale.language(chosen) {
    "en" -> english_translations()
    _ -> swedish_translations()
  }
  g18n.new_translator(chosen, translations)
}

fn app_bar_title(translator: Translator, page: Page) -> Option(String) {
  case page {
    ActivitiesListPage(_) ->
      Some(g18n.translate(translator, "app_bar.activities_list"))
    ActivityDetailPage(_, _) ->
      Some(g18n.translate(translator, "app_bar.activity_detail"))
    ActivityNewPage(_, _) ->
      Some(g18n.translate(translator, "app_bar.activity_new"))
    ActivityEditPage(_, _) -> None
    NotFoundPage -> None
  }
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let #(page, page_effect) = case modem.initial_uri() {
    Ok(uri) -> uri_to_page(uri)
    Error(_) -> #(ActivitiesListPage(Loading), fetch_activities())
  }

  let translator = translator_for(get_html_lang())

  let model = Model(page:, translator:)

  let title_effect = case app_bar_title(translator, page) {
    Some(title) -> set_app_bar_title(title)
    None -> effect.none()
  }

  #(
    model,
    effect.batch([
      modem.init(OnRouteChange),
      observe_lang(),
      page_effect,
      title_effect,
    ]),
  )
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  // Routing
  OnRouteChange(Uri)
  // Locale
  LangChanged(String)
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
      let #(page, page_effect) = uri_to_page(uri)
      let title_effect = case app_bar_title(model.translator, page) {
        Some(title) -> set_app_bar_title(title)
        None -> effect.none()
      }
      #(Model(..model, page:), effect.batch([page_effect, title_effect]))
    }

    LangChanged(lang) -> {
      let translator = translator_for(lang)
      let title_effect = case app_bar_title(translator, model.page) {
        Some(title) -> set_app_bar_title(title)
        None -> effect.none()
      }
      #(Model(..model, translator:), title_effect)
    }

    ApiReturnedActivities(result) ->
      case model.page {
        ActivitiesListPage(Loading) -> {
          let new_state = case result {
            Ok(activities) -> Loaded(activities)
            Error(_) -> Failed("Failed to load activities")
          }
          #(Model(..model, page: ActivitiesListPage(new_state)), effect.none())
        }
        _ -> #(model, effect.none())
      }

    ApiReturnedActivity(result) ->
      case model.page {
        ActivityDetailPage(id, Loading) -> {
          let new_state = case result {
            Ok(activity) -> Loaded(activity)
            Error(_) -> Failed("Failed to load activity")
          }
          #(
            Model(..model, page: ActivityDetailPage(id, new_state)),
            effect.none(),
          )
        }
        ActivityEditPage(id, EditLoading) -> {
          let new_state = case result {
            Ok(activity) ->
              EditReady(activity, form_from_activity(activity), None)
            Error(_) -> EditLoadFailed("Failed to load activity")
          }
          #(
            Model(..model, page: ActivityEditPage(id, new_state)),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }

    ApiCreatedActivity(Ok(_)) -> #(
      model,
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiCreatedActivity(Error(_)) ->
      case model.page {
        ActivityNewPage(form, _) -> #(
          Model(
            ..model,
            page: ActivityNewPage(form, Some("Failed to create activity")),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    ApiUpdatedActivity(Ok(activity)) ->
      case model.page {
        ActivityEditPage(id, _) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(activity, form_from_activity(activity), None),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    ApiUpdatedActivity(Error(_)) ->
      case model.page {
        ActivityEditPage(id, EditReady(activity, form, _)) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(activity, form, Some("Failed to update activity")),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    ApiDeletedActivity(Ok(_)) -> #(
      model,
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiDeletedActivity(Error(_)) ->
      case model.page {
        ActivityEditPage(id, EditReady(activity, form, _)) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(activity, form, Some("Failed to delete activity")),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedCreateForm(Ok(activity_form)) -> #(
      model,
      create_activity(activity_form),
    )

    UserSubmittedCreateForm(Error(f)) ->
      case model.page {
        ActivityNewPage(_, submit_error) -> #(
          Model(..model, page: ActivityNewPage(f, submit_error)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedEditForm(Ok(activity_form)) ->
      case model.page {
        ActivityEditPage(id, EditReady(_, _, _)) -> #(
          model,
          update_activity(id, activity_form),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedEditForm(Error(f)) ->
      case model.page {
        ActivityEditPage(id, EditReady(activity, _, submit_error)) -> #(
          Model(
            ..model,
            page: ActivityEditPage(id, EditReady(activity, f, submit_error)),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserClickedEdit -> #(model, effect.none())

    UserClickedCancelEdit ->
      case model.page {
        ActivityEditPage(id, EditReady(activity, _, _)) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(activity, form_from_activity(activity), None),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserClickedDelete ->
      case model.page {
        ActivityEditPage(id, EditReady(_, _, _)) -> #(
          model,
          delete_activity(id),
        )
        _ -> #(model, effect.none())
      }
  }
}

// EFFECTS ---------------------------------------------------------------------

@external(javascript, "./client_ffi.mjs", "post_message_to_parent")
fn post_message_to_parent(type_: String, title: String) -> Nil

@external(javascript, "./client_ffi.mjs", "get_html_lang")
fn get_html_lang() -> String

@external(javascript, "./client_ffi.mjs", "observe_html_lang")
fn observe_html_lang(callback: fn(String) -> Nil) -> Nil

fn set_app_bar_title(title: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { post_message_to_parent("j26:appBar", title) })
}

fn observe_lang() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    observe_html_lang(fn(lang) { dispatch(LangChanged(lang)) })
  })
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

fn uri_to_page(uri: Uri) -> #(Page, Effect(Msg)) {
  case uri.path_segments(uri.path) |> list.drop(2) {
    ["activities"] | [] -> #(ActivitiesListPage(Loading), fetch_activities())
    ["activities", "new"] -> #(
      ActivityNewPage(activity_form(), None),
      effect.none(),
    )
    ["activities", id] -> #(ActivityDetailPage(id, Loading), fetch_activity(id))
    _ -> #(NotFoundPage, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.page {
    ActivitiesListPage(state) -> view_activities_list(model.translator, state)
    ActivityNewPage(form, submit_error) -> view_activity_new(form, submit_error)
    ActivityDetailPage(_, state) ->
      view_activity_detail(model.translator, state)
    ActivityEditPage(_, _) -> todo
    NotFoundPage -> view_not_found()
  }
}

fn view_activities_list(
  translator: Translator,
  state: RemoteData(List(Activity)),
) -> Element(Msg) {
  html.div([attribute.class("flex flex-col")], [
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("justify-content", "space-between"),
          #("align-items", "center"),
          #("padding", "var(--spacing-4)"),
        ]),
      ],
      [
        html.a(
          [
            attribute.href(api_prefix <> "/activities/new"),
            attribute.styles([#("text-decoration", "none")]),
          ],
          [component.scout_button_icon("Create", "primary", "plus")],
        ),
      ],
    ),
    case state {
      Loading ->
        html.div([attribute.styles([#("padding", "var(--spacing-6)")])], [
          component.scout_loader("Loading activities..."),
        ])
      Failed(err) -> component.error_banner(err)
      Loaded([]) ->
        html.div(
          [
            attribute.styles([
              #("padding", "var(--spacing-6)"),
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
              [component.scout_button_el("Create first activity", "primary")],
            ),
          ],
        )
      Loaded(activities) ->
        element.element("scout-list-view", [], {
          use activity <- list.map(activities)
          let id = uuid.to_string(activity.id)
          let secondary =
            format_time_range(
              translator,
              activity.start_time,
              activity.end_time,
            )
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
    },
  ])
}

fn view_activity_new(
  form: Form(ActivityForm),
  submit_error: Option(String),
) -> Element(Msg) {
  let submitted = fn(values) {
    form
    |> form.add_values(values)
    |> form.run
    |> UserSubmittedCreateForm
  }
  html.div([attribute.class("flex flex-col")], [
    html.div([attribute.styles([#("padding", "var(--spacing-4)")])], [
      html.h1([], [element.text("New Activity")]),
    ]),
    html.div([attribute.styles([#("padding", "var(--spacing-4)")])], [
      case submit_error {
        Some(err) -> component.error_banner(err)
        None -> element.none()
      },
      html.form([event.on_submit(submitted)], [
        component.scout_card([
          html.div([attribute.class("flex flex-col gap-2")], [
            component.scout_form_field(form, "Title", "text", "title"),
            component.scout_form_field(
              form,
              "Description",
              "text",
              "description",
            ),
            component.scout_form_field(
              form,
              "Max attendees",
              "number",
              "max_attendees",
            ),
            component.scout_form_field(
              form,
              "Start time",
              "datetime-local",
              "start_time",
            ),
            component.scout_form_field(
              form,
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

fn view_activity_detail(
  translator: Translator,
  state: RemoteData(Activity),
) -> Element(Msg) {
  case state {
    Loading ->
      html.div([attribute.class("flex justify-center py-8")], [
        component.scout_loader(g18n.translate(translator, "activity.loading")),
      ])
    Failed(_) ->
      html.div([attribute.class("flex flex-col")], [
        html.div(
          [
            attribute.styles([
              #("display", "flex"),
              #("align-items", "center"),
              #("gap", "var(--spacing-2)"),
              #("padding", "var(--spacing-4)"),
            ]),
          ],
          [
            html.h1([], [
              element.text(g18n.translate(
                translator,
                "activity.not_found_title",
              )),
            ]),
          ],
        ),
        html.div([attribute.styles([#("padding", "var(--spacing-6)")])], [
          html.p([], [
            element.text(g18n.translate(
              translator,
              "activity.not_found_message",
            )),
          ]),
        ]),
      ])
    Loaded(activity) -> view_activity_detail_loaded(translator, activity)
  }
}

fn view_activity_detail_loaded(
  translator: Translator,
  activity: Activity,
) -> Element(Msg) {
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
              component.scout_button_action(
                g18n.translate(translator, "activity.book"),
                "primary",
                UserClickedEdit,
              ),
              // TODO: Change button to "Spara" when no max attendees?
              case activity.max_attendees {
                Some(max_attendees) ->
                  html.div(
                    [
                      attribute.class(
                        "flex gap-2 items-center text-body-sm text-gray-500",
                      ),
                    ],
                    [
                      component.icon(icons.users, "size-4"),
                      html.p([attribute.class("flex-1")], [
                        element.text(g18n.translate_plural(
                          translator,
                          "activity.spots_remaining",
                          max_attendees,
                          // TODO: do real calculation based on bookings
                        )),
                      ]),
                    ],
                  )
                None -> element.none()
              },
            ]),
          ],
        ),
        html.div(
          [
            // Quick info
            attribute.class("flex-1 grid grid-cols-2"),
          ],
          [
            component.quick_info_tile(
              icons.clock,
              g18n.translate(translator, "activity.time"),
              [
                view_time_interval(
                  translator,
                  activity.start_time,
                  activity.end_time,
                ),
              ],
            ),
            component.quick_info_tile(
              icons.pin,
              g18n.translate(translator, "activity.location"),
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
          ]),
        ]),
      ],
    ),
  ])
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
  translator: Translator,
  start: timestamp.Timestamp,
  end: timestamp.Timestamp,
) -> Element(Msg) {
  let start_calendar = timestamp.to_calendar(start, calendar.local_offset())
  let end_calendar = timestamp.to_calendar(end, calendar.local_offset())
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
        g18n.translate(translator, "activity.date_range_separator")
      html.span([], [
        element.text(
          format_date(start_calendar.0)
          <> " "
          <> format_time(start_calendar.1)
          <> " "
          <> separator,
        ),
        html.br([]),
        element.text(
          format_date(end_calendar.0) <> " " <> format_time(end_calendar.1),
        ),
      ])
    }
  }
}

fn view_not_found() -> Element(Msg) {
  html.div([attribute.class("flex flex-col")], [
    html.div([attribute.styles([#("padding", "var(--spacing-4)")])], [
      html.h1([], [element.text("Not Found")]),
    ]),
    html.div([attribute.styles([#("padding", "var(--spacing-6)")])], [
      html.p([], [element.text("Page not found.")]),
      html.a([attribute.href(api_prefix <> "/activities")], [
        element.text("Go to activities"),
      ]),
    ]),
  ])
}

// HELPERS ---------------------------------------------------------------------

fn format_time_range(
  translator: g18n.Translator,
  start: timestamp.Timestamp,
  end: timestamp.Timestamp,
) -> String {
  let fmt = fn(ts) {
    let #(_, time) = timestamp.to_calendar(ts, calendar.local_offset())
    g18n.format_time(translator, time, g18n.Short)
  }
  fmt(start) <> " – " <> fmt(end)
}
