import component
import formal/form.{type Form}
import g18n.{type Translator}
import g18n/locale
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/set.{type Set}
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}
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
import shared/model.{type Activity, type Booking}
import youid/uuid.{type Uuid}

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
  |> g18n.add_translation("activity.booked", "Booked!")
  |> g18n.add_translation("list.search_placeholder", "Search")
  |> g18n.add_translation("list.filter.all", "All")
  |> g18n.add_translation("list.filter.booked", "Booked")
  |> g18n.add_translation("list.filter.more", "More filters")
  |> g18n.add_translation("list.filter.audience_label", "Target audience")
  |> g18n.add_translation("list.filter.tags_label", "Tags")
  |> g18n.add_translation("list.bucket.forenoon", "Morning")
  |> g18n.add_translation("list.bucket.afternoon", "Afternoon")
  |> g18n.add_translation("list.bucket.evening", "Evening")
  |> g18n.add_translation("list.bucket.now_suffix", " (now)")
  |> g18n.add_translation("list.bucket.now_label", "Now")
  |> g18n.add_translation("list.day.any", "All days")
  |> g18n.add_translation(
    "list.empty_filtered",
    "No activities match the filters.",
  )
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
  |> g18n.add_translation("activity.booked", "Bokat!")
  |> g18n.add_translation("list.search_placeholder", "Sök")
  |> g18n.add_translation("list.filter.all", "Alla")
  |> g18n.add_translation("list.filter.booked", "Bokade")
  |> g18n.add_translation("list.filter.more", "Fler filter")
  |> g18n.add_translation("list.filter.audience_label", "Målgrupp")
  |> g18n.add_translation("list.filter.tags_label", "Taggar")
  |> g18n.add_translation("list.bucket.forenoon", "Förmiddag")
  |> g18n.add_translation("list.bucket.afternoon", "Eftermiddag")
  |> g18n.add_translation("list.bucket.evening", "Kväll")
  |> g18n.add_translation("list.bucket.now_suffix", " (nu)")
  |> g18n.add_translation("list.bucket.now_label", "Nu")
  |> g18n.add_translation("list.day.any", "Alla dagar")
  |> g18n.add_translation(
    "list.empty_filtered",
    "Inga aktiviteter matchar filtren.",
  )
}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

pub type ActivityWithBookingStatus {
  ActivityWithBookingStatus(activity: Activity, booked: Bool)
}

pub type ActivityWithBooking {
  ActivityWithBooking(activity: Activity, booking: Booking)
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

type BookingFilter {
  AllActivities
  BookedOnly
}

type ListFilters {
  ListFilters(
    search: String,
    booking: BookingFilter,
    day: Option(calendar.Date),
    more_open: Bool,
    audiences: List(String),
    tags: List(String),
  )
}

fn default_filters() -> ListFilters {
  ListFilters(
    search: "",
    booking: AllActivities,
    day: None,
    more_open: False,
    audiences: [],
    tags: [],
  )
}

type Page {
  ActivitiesListPage(
    state: RemoteData(List(ActivityWithBookingStatus)),
    filters: ListFilters,
  )
  ActivityNewPage(form: Form(ActivityForm), submit_error: Option(String))
  ActivityDetailPage(id: String, state: RemoteData(ActivityWithBookingStatus))
  ActivityEditPage(id: String, state: EditState)
  NotFoundPage
}

type Model {
  Model(page: Page, translator: Translator, my_bookings: List(Booking))
}

fn booked_set(bookings: List(Booking)) -> Set(Uuid) {
  bookings |> list.map(fn(b) { b.activity_id }) |> set.from_list
}

fn wrap_activity(
  activity: Activity,
  bookings: List(Booking),
) -> ActivityWithBookingStatus {
  ActivityWithBookingStatus(
    activity:,
    booked: set.contains(booked_set(bookings), activity.id),
  )
}

fn wrap_activities(
  activities: List(Activity),
  bookings: List(Booking),
) -> List(ActivityWithBookingStatus) {
  let booked = booked_set(bookings)
  list.map(activities, fn(a) {
    ActivityWithBookingStatus(activity: a, booked: set.contains(booked, a.id))
  })
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
    ActivitiesListPage(_, _) ->
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
    Error(_) -> #(
      ActivitiesListPage(Loading, default_filters()),
      fetch_activities(),
    )
  }

  let translator = translator_for(get_html_lang())

  let model = Model(page:, translator:, my_bookings: [])

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
      fetch_my_bookings(),
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
  ApiReturnedMyBookings(Result(List(Booking), rsvp.Error))
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
  // List page filters
  UserSearchedActivities(String)
  UserSelectedBookingFilter(BookingFilter)
  UserSelectedDay(Option(calendar.Date))
  UserToggledMoreFilters
  UserToggledAudience(String)
  UserToggledTag(String)
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
        ActivitiesListPage(Loading, filters) -> {
          let new_state = case result {
            Ok(activities) ->
              Loaded(wrap_activities(activities, model.my_bookings))
            Error(_) -> Failed("Failed to load activities")
          }
          #(
            Model(..model, page: ActivitiesListPage(new_state, filters)),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }

    ApiReturnedActivity(result) ->
      case model.page {
        ActivityDetailPage(id, Loading) -> {
          let new_state = case result {
            Ok(activity) -> Loaded(wrap_activity(activity, model.my_bookings))
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

    ApiReturnedMyBookings(result) -> {
      let bookings = case result {
        Ok(bs) -> bs
        Error(_) -> model.my_bookings
      }
      let new_page = case model.page {
        ActivitiesListPage(Loaded(activities_with_booking_status), filters) -> {
          let activities =
            list.map(
              activities_with_booking_status,
              fn(activity_with_booking_status) {
                activity_with_booking_status.activity
              },
            )
          ActivitiesListPage(
            Loaded(wrap_activities(activities, bookings)),
            filters,
          )
        }
        ActivityDetailPage(id, Loaded(activity_with_booking_status)) ->
          ActivityDetailPage(
            id,
            Loaded(wrap_activity(
              activity_with_booking_status.activity,
              bookings,
            )),
          )
        other -> other
      }
      #(Model(..model, page: new_page, my_bookings: bookings), effect.none())
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

    UserSearchedActivities(value) ->
      update_filters(model, fn(f) { ListFilters(..f, search: value) })

    UserSelectedBookingFilter(b) ->
      update_filters(model, fn(f) { ListFilters(..f, booking: b) })

    UserSelectedDay(d) ->
      update_filters(model, fn(f) { ListFilters(..f, day: d) })

    UserToggledMoreFilters ->
      update_filters(model, fn(f) { ListFilters(..f, more_open: !f.more_open) })

    UserToggledAudience(name) ->
      update_filters(model, fn(f) {
        ListFilters(..f, audiences: toggle_member(f.audiences, name))
      })

    UserToggledTag(name) ->
      update_filters(model, fn(f) {
        ListFilters(..f, tags: toggle_member(f.tags, name))
      })
  }
}

fn update_filters(
  model: Model,
  f: fn(ListFilters) -> ListFilters,
) -> #(Model, Effect(Msg)) {
  case model.page {
    ActivitiesListPage(state, filters) -> #(
      Model(..model, page: ActivitiesListPage(state, f(filters))),
      effect.none(),
    )
    _ -> #(model, effect.none())
  }
}

fn toggle_member(items: List(String), name: String) -> List(String) {
  case list.contains(items, name) {
    True -> list.filter(items, fn(i) { i != name })
    False -> [name, ..items]
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

fn fetch_my_bookings() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/bookings/me",
    rsvp.expect_json(model.bookings_decoder(), ApiReturnedMyBookings),
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
    ["activities"] | [] -> #(
      ActivitiesListPage(Loading, default_filters()),
      fetch_activities(),
    )
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
    ActivitiesListPage(state, filters) ->
      view_activities_list(model.translator, state, filters)
    ActivityNewPage(form, submit_error) -> view_activity_new(form, submit_error)
    ActivityDetailPage(_, state) ->
      view_activity_detail(model.translator, state)
    ActivityEditPage(_, _) -> todo
    NotFoundPage -> view_not_found()
  }
}

fn view_activities_list(
  translator: Translator,
  state: RemoteData(List(ActivityWithBookingStatus)),
  filters: ListFilters,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }

  html.div([attribute.class("flex flex-col gap-3 p-4")], [
    view_list_top_bar(translator, filters, state),
    case filters.more_open {
      True -> view_more_filters_panel(translator, filters)
      False -> element.none()
    },
    case state {
      Loading -> component.scout_loader(t("activity.loading"))
      Failed(err) -> component.error_banner(err)
      Loaded([]) ->
        html.div([attribute.class("py-6 text-center flex flex-col gap-3")], [
          html.p([], [element.text("No activities yet.")]),
          html.a(
            [
              attribute.href(api_prefix <> "/activities/new"),
              attribute.class("no-underline self-center"),
            ],
            [component.scout_button_el("Create first activity", "primary")],
          ),
        ])
      Loaded(activities) ->
        view_grouped_activities(translator, activities, filters)
    },
  ])
}

fn view_list_top_bar(
  translator: Translator,
  filters: ListFilters,
  state: RemoteData(List(ActivityWithBookingStatus)),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let dates = case state {
    Loaded(activities) -> camp_dates(activities)
    _ -> []
  }
  let booking_index = case filters.booking {
    AllActivities -> 0
    BookedOnly -> 1
  }
  html.div([attribute.class("flex flex-col gap-2")], [
    component.scout_input_search(
      filters.search,
      t("list.search_placeholder"),
      UserSearchedActivities,
    ),
    html.div([attribute.class("flex items-center gap-2")], [
      component.scout_segmented_control(
        booking_index,
        [t("list.filter.all"), t("list.filter.booked")],
        fn(idx) {
          case idx {
            0 -> UserSelectedBookingFilter(AllActivities)
            _ -> UserSelectedBookingFilter(BookedOnly)
          }
        },
        [attribute.class("max-w-48")],
      ),
      html.div([attribute.class("ml-auto flex items-center gap-2")], [
        view_day_select(translator, filters.day, dates),
        component.filter_pill_icon(
          t("list.filter.more"),
          icons.filter,
          filters.more_open,
          UserToggledMoreFilters,
        ),
      ]),
    ]),
  ])
}

fn view_day_select(
  translator: Translator,
  selected: Option(calendar.Date),
  dates: List(calendar.Date),
) -> Element(Msg) {
  let any_value = "__any__"
  let selected_value = case selected {
    None -> any_value
    Some(date) -> date_to_iso(date)
  }
  let any_option =
    html.option(
      [
        attribute.value(any_value),
        attribute.selected(selected_value == any_value),
      ],
      g18n.translate(translator, "list.day.any"),
    )
  let date_options =
    list.map(dates, fn(date) {
      let value = date_to_iso(date)
      let label = g18n.format_date(translator, date, g18n.Custom("EEEE d/M"))
      html.option(
        [attribute.value(value), attribute.selected(value == selected_value)],
        label,
      )
    })
  element.element(
    "scout-select",
    [
      attribute.class("min-w-40"),
      attribute.attribute("name", "day"),
      attribute.attribute("value", selected_value),
      event.on("scoutInputChange", {
        use value <- decode.subfield(["detail", "value"], decode.string)
        let new_day = case value {
          "__any__" -> None
          iso -> parse_date_iso(iso)
        }
        decode.success(UserSelectedDay(new_day))
      }),
    ],
    [any_option, ..date_options],
  )
}

fn view_more_filters_panel(
  translator: Translator,
  filters: ListFilters,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  component.scout_card([
    html.div([attribute.class("flex flex-col gap-3 p-2")], [
      html.div([attribute.class("flex flex-col gap-2")], [
        html.h4([attribute.class("text-body-sm font-semibold")], [
          element.text(t("list.filter.audience_label")),
        ]),
        html.div(
          [attribute.class("flex flex-wrap gap-2")],
          list.map(audience_options(), fn(name) {
            component.filter_chip(
              name,
              list.contains(filters.audiences, name),
              UserToggledAudience(name),
            )
          }),
        ),
      ]),
      html.div([attribute.class("flex flex-col gap-2")], [
        html.h4([attribute.class("text-body-sm font-semibold")], [
          element.text(t("list.filter.tags_label")),
        ]),
        html.div(
          [attribute.class("flex flex-wrap gap-2")],
          list.map(tag_options(), fn(name) {
            component.filter_chip(
              name,
              list.contains(filters.tags, name),
              UserToggledTag(name),
            )
          }),
        ),
      ]),
    ]),
  ])
}

fn view_grouped_activities(
  translator: Translator,
  activities: List(ActivityWithBookingStatus),
  filters: ListFilters,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let filtered =
    apply_filters(activities, filters)
    |> list.sort(fn(a, b) {
      timestamp.compare(a.activity.start_time, b.activity.start_time)
    })
  case filtered {
    [] ->
      html.div(
        [
          attribute.class(
            "py-12 px-6 text-center flex flex-col items-center gap-2 text-gray-500",
          ),
        ],
        [
          html.div([attribute.class("size-10 text-gray-400")], [
            component.icon(icons.filter, "size-full"),
          ]),
          html.p([attribute.class("text-body-base")], [
            element.text(t("list.empty_filtered")),
          ]),
        ],
      )
    _ -> {
      let groups = group_by_date_bucket(filtered)
      let now_ts = timestamp.system_time()
      let today = date_of(now_ts)
      let now_bucket = current_bucket()
      html.div(
        [attribute.class("flex flex-col gap-4")],
        list.map(groups, fn(group) {
          let #(#(date, bucket), items) = group
          let is_current = date == today && bucket == now_bucket
          view_section(translator, date, bucket, items, is_current)
        }),
      )
    }
  }
}

fn group_by_date_bucket(
  activities: List(ActivityWithBookingStatus),
) -> List(#(#(calendar.Date, TimeBucket), List(ActivityWithBookingStatus))) {
  let key_for = fn(activity_with_booking_status: ActivityWithBookingStatus) {
    #(
      date_of(activity_with_booking_status.activity.start_time),
      bucket_for(activity_with_booking_status.activity.start_time),
    )
  }
  let grouped = list.group(activities, by: key_for)
  let key_compare = fn(a, b) {
    let #(d1, b1) = a
    let #(d2, b2) = b
    case calendar.naive_date_compare(d1, d2) {
      order.Eq -> int.compare(bucket_ordinal(b1), bucket_ordinal(b2))
      other -> other
    }
  }
  let keys = dict.keys(grouped) |> list.sort(key_compare)
  list.map(keys, fn(key) {
    let items =
      dict.get(grouped, key)
      |> result_unwrap_or([])
      |> list.sort(fn(a, b) {
        timestamp.compare(a.activity.start_time, b.activity.start_time)
      })
    #(key, items)
  })
}

fn result_unwrap_or(r: Result(a, e), default: a) -> a {
  case r {
    Ok(v) -> v
    Error(_) -> default
  }
}

fn view_section(
  translator: Translator,
  date: calendar.Date,
  bucket: TimeBucket,
  activities: List(ActivityWithBookingStatus),
  is_current: Bool,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let bucket_label = t(bucket_translation_key(bucket))
  let date_label = format_date_short(translator, date)
  html.section([attribute.class("flex flex-col gap-2")], [
    html.div([attribute.class("flex items-baseline gap-2 mt-2")], [
      html.span(
        [
          attribute.class(
            "text-xs font-semibold uppercase tracking-wider text-gray-500",
          ),
        ],
        [element.text(bucket_label)],
      ),
      html.h2([attribute.class("text-body-base font-semibold text-gray-900")], [
        element.text(date_label),
      ]),
      case is_current {
        True ->
          html.span(
            [
              attribute.class(
                "text-xs font-bold uppercase tracking-wider rounded-full px-2 py-0.5 bg-blue-700 text-white",
              ),
            ],
            [element.text(t("list.bucket.now_label"))],
          )
        False -> element.none()
      },
    ]),
    html.div(
      [attribute.class("flex flex-col gap-2")],
      list.map(activities, fn(activity_with_booking_status) {
        view_activity_card(translator, date, activity_with_booking_status)
      }),
    ),
  ])
}

fn view_activity_card(
  translator: Translator,
  section_date: calendar.Date,
  activity_with_booking_status: ActivityWithBookingStatus,
) -> Element(Msg) {
  let activity = activity_with_booking_status.activity
  let id = uuid.to_string(activity.id)
  let time =
    view_card_time(
      translator,
      activity.start_time,
      activity.end_time,
      section_date,
    )
  let location = mock_location(activity.id)
  let spots = mock_spots_remaining(activity)
  let spots_text =
    g18n.translate_plural(translator, "activity.spots_remaining", spots)
  component.activity_card(
    api_prefix <> "/activities/" <> id,
    activity.title,
    activity_with_booking_status.booked,
    g18n.translate(translator, "activity.booked"),
    time,
    location,
    spots_text,
  )
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
  state: RemoteData(ActivityWithBookingStatus),
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
    Loaded(activity_with_booking_status) ->
      view_activity_detail_loaded(
        translator,
        activity_with_booking_status.activity,
      )
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

fn format_date_short(translator: Translator, d: calendar.Date) -> String {
  g18n.format_date(translator, d, g18n.Custom("EEEE d/M"))
}

fn format_clock(translator: Translator, tod: calendar.TimeOfDay) -> String {
  g18n.format_time(translator, tod, g18n.Custom("HH.mm"))
}

/// Multi-line cross-day time with `to` separator, used by detail and list card
/// when the activity spans multiple days.
fn view_cross_day_interval(
  translator: Translator,
  start_calendar: #(calendar.Date, calendar.TimeOfDay),
  end_calendar: #(calendar.Date, calendar.TimeOfDay),
) -> Element(msg) {
  let separator = g18n.translate(translator, "activity.date_range_separator")
  html.span([], [
    element.text(
      format_date_short(translator, start_calendar.0)
      <> " "
      <> format_clock(translator, start_calendar.1)
      <> " "
      <> separator,
    ),
    html.br([]),
    element.text(
      format_date_short(translator, end_calendar.0)
      <> " "
      <> format_clock(translator, end_calendar.1),
    ),
  ])
}

/// Time element for the activity card. The section header already shows the
/// start date, so we drop it here. Cross-day activities show only the end date
/// with a `→` arrow, keeping the meta row tight and aligned with the same-day
/// formats.
fn view_card_time(
  translator: Translator,
  start: timestamp.Timestamp,
  end: timestamp.Timestamp,
  section_date: calendar.Date,
) -> Element(msg) {
  let start_calendar = timestamp.to_calendar(start, calendar.local_offset())
  let end_calendar = timestamp.to_calendar(end, calendar.local_offset())
  case classify_interval(start_calendar, end_calendar) {
    SameDaySameTime -> element.text(format_clock(translator, start_calendar.1))
    SameDayDifferentTime ->
      element.text(
        format_clock(translator, start_calendar.1)
        <> " – "
        <> format_clock(translator, end_calendar.1),
      )
    DifferentDays -> {
      let start_clock = format_clock(translator, start_calendar.1)
      let end_clock = format_clock(translator, end_calendar.1)
      let end_date_short = format_date_short(translator, end_calendar.0)
      case section_date == start_calendar.0 {
        True ->
          element.text(
            start_clock <> " → " <> end_date_short <> " " <> end_clock,
          )
        False ->
          view_cross_day_interval(translator, start_calendar, end_calendar)
      }
    }
  }
}

fn view_time_interval(
  translator: Translator,
  start: timestamp.Timestamp,
  end: timestamp.Timestamp,
) -> Element(Msg) {
  let start_calendar = timestamp.to_calendar(start, calendar.local_offset())
  let end_calendar = timestamp.to_calendar(end, calendar.local_offset())
  case classify_interval(start_calendar, end_calendar) {
    SameDayDifferentTime ->
      html.span([], [
        element.text(format_date_short(translator, start_calendar.0)),
        html.br([]),
        element.text(
          format_clock(translator, start_calendar.1)
          <> " - "
          <> format_clock(translator, end_calendar.1),
        ),
      ])
    SameDaySameTime ->
      html.span([], [
        element.text(format_date_short(translator, start_calendar.0)),
        html.br([]),
        element.text(format_clock(translator, start_calendar.1)),
      ])
    DifferentDays ->
      view_cross_day_interval(translator, start_calendar, end_calendar)
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

// MOCK -----------------------------------------------------------------------
// TODO: replace with real data once schema is extended with location, tags,
// target audience, and bookings.

fn id_seed(id: Uuid) -> Int {
  uuid.to_string(id)
  |> string.to_utf_codepoints
  |> list.fold(0, fn(acc, cp) { acc + string.utf_codepoint_to_int(cp) })
}

fn pick_at(items: List(a), seed: Int, default: a) -> a {
  let n = list.length(items)
  case n {
    0 -> default
    _ -> {
      let idx = seed % n
      case list.drop(items, idx) |> list.first {
        Ok(value) -> value
        Error(_) -> default
      }
    }
  }
}

const mock_locations: List(String) = [
  "Badbusstorget", "Lägerelden", "Stora ängen", "Aktivitetstältet", "Hjärtat",
]

fn audience_options() -> List(String) {
  ["Spårare", "Upptäckare", "Äventyrare", "Utmanare", "Rover"]
}

fn tag_options() -> List(String) {
  ["Fysisk", "Badbuss", "Mat", "Skapande", "Lugn"]
}

fn mock_location(id: Uuid) -> String {
  pick_at(mock_locations, id_seed(id), "Badbusstorget")
}

fn mock_audiences(id: Uuid) -> List(String) {
  let opts = audience_options()
  let seed = id_seed(id)
  let first = pick_at(opts, seed, "Spårare")
  let second = pick_at(opts, seed / 7 + 1, "Utmanare")
  case first == second {
    True -> [first]
    False -> [first, second]
  }
}

fn mock_tags(id: Uuid) -> List(String) {
  let opts = tag_options()
  let seed = id_seed(id)
  let first = pick_at(opts, seed / 3, "Fysisk")
  let second = pick_at(opts, seed / 11 + 2, "Badbuss")
  case first == second {
    True -> [first]
    False -> [first, second]
  }
}

fn mock_spots_remaining(activity: Activity) -> Int {
  case activity.max_attendees {
    Some(max) -> {
      let taken = id_seed(activity.id) % { max + 1 }
      let remaining = max - taken
      case remaining < 0 {
        True -> 0
        False -> remaining
      }
    }
    None -> 0
  }
}

// TIME BUCKETS ---------------------------------------------------------------

type TimeBucket {
  Forenoon
  Afternoon
  Evening
}

fn bucket_for(ts: Timestamp) -> TimeBucket {
  let #(_, time) = timestamp.to_calendar(ts, calendar.local_offset())
  case time.hours {
    h if h < 12 -> Forenoon
    h if h < 18 -> Afternoon
    _ -> Evening
  }
}

fn bucket_ordinal(b: TimeBucket) -> Int {
  case b {
    Forenoon -> 0
    Afternoon -> 1
    Evening -> 2
  }
}

fn bucket_translation_key(bucket: TimeBucket) -> String {
  case bucket {
    Forenoon -> "list.bucket.forenoon"
    Afternoon -> "list.bucket.afternoon"
    Evening -> "list.bucket.evening"
  }
}

fn current_bucket() -> TimeBucket {
  bucket_for(timestamp.system_time())
}

// FILTERING ------------------------------------------------------------------

fn date_of(ts: Timestamp) -> calendar.Date {
  let #(date, _) = timestamp.to_calendar(ts, calendar.local_offset())
  date
}

fn lists_intersect(a: List(String), b: List(String)) -> Bool {
  list.any(a, fn(x) { list.contains(b, x) })
}

fn apply_filters(
  activities: List(ActivityWithBookingStatus),
  f: ListFilters,
) -> List(ActivityWithBookingStatus) {
  let needle = string.lowercase(string.trim(f.search))
  use activity_with_booking_status <- list.filter(activities)
  let activity = activity_with_booking_status.activity
  let title_match = case needle {
    "" -> True
    _ -> string.contains(string.lowercase(activity.title), needle)
  }
  let day_match = case f.day {
    None -> True
    Some(date) -> date_of(activity.start_time) == date
  }
  let booked_match = case f.booking {
    AllActivities -> True
    BookedOnly -> activity_with_booking_status.booked
  }
  let audience_match = case f.audiences {
    [] -> True
    selected -> lists_intersect(mock_audiences(activity.id), selected)
  }
  let tag_match = case f.tags {
    [] -> True
    selected -> lists_intersect(mock_tags(activity.id), selected)
  }
  title_match && day_match && booked_match && audience_match && tag_match
}

fn camp_dates(
  activities: List(ActivityWithBookingStatus),
) -> List(calendar.Date) {
  activities
  |> list.map(fn(activity_with_booking_status) {
    date_of(activity_with_booking_status.activity.start_time)
  })
  |> list.unique
  |> list.sort(calendar.naive_date_compare)
}

fn date_to_iso(date: calendar.Date) -> String {
  timestamp.from_calendar(
    date,
    calendar.TimeOfDay(0, 0, 0, 0),
    calendar.utc_offset,
  )
  |> timestamp.to_rfc3339(calendar.utc_offset)
  |> string.slice(0, 10)
}

fn parse_date_iso(s: String) -> Option(calendar.Date) {
  case timestamp.parse_rfc3339(s <> "T00:00:00Z") {
    Ok(ts) -> {
      let #(date, _) = timestamp.to_calendar(ts, calendar.utc_offset)
      Some(date)
    }
    Error(_) -> None
  }
}
