import component
import formal/form.{type Form}
import g18n.{type Translator}
import g18n/locale
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
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
import shared/model.{
  type Activity, type ActivityStatus, type ActivityStatusEntry,
  type ActivitySummary, type Booking, Booked, Favourited, NotInterested,
}
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
  |> g18n.add_translation("activity.booked", "Booked")
  |> g18n.add_translation("activity.needs_booking", "Needs booking")
  |> g18n.add_translation("booking.responsible_name", "Responsible adult")
  |> g18n.add_translation("booking.phone_number", "Phone number")
  |> g18n.add_translation("booking.group_free_text", "Group / patrol")
  |> g18n.add_translation("booking.participant_count", "Number of participants")
  |> g18n.add_translation("booking.submit", "Save")
  |> g18n.add_translation("booking.cancel", "Cancel")
  |> g18n.add_translation("booking.submitting", "Saving booking...")
  |> g18n.add_translation("booking.change", "Change booking")
  |> g18n.add_translation("booking.unbook", "Cancel booking")
  |> g18n.add_translation("booking.confirm_unbook", "Yes, cancel")
  |> g18n.add_translation("list.search_placeholder", "Search")
  |> g18n.add_translation("list.filter.all", "All")
  |> g18n.add_translation("list.tab.activities", "Activities")
  |> g18n.add_translation("list.tab.badbuss", "Swim bus")
  |> g18n.add_translation("list.tab.climbing_wall", "Climbing wall")
  |> g18n.add_translation("list.filter.favourites", "Favourites")
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
  |> g18n.add_translation("list.retry", "Try again")
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
  |> g18n.add_translation("activity.booked", "Bokad")
  |> g18n.add_translation("activity.needs_booking", "Behöver bokas")
  |> g18n.add_translation("booking.responsible_name", "Ansvarig ledare")
  |> g18n.add_translation("booking.phone_number", "Telefonnummer")
  |> g18n.add_translation("booking.group_free_text", "Grupp / patrull")
  |> g18n.add_translation("booking.participant_count", "Antal deltagare")
  |> g18n.add_translation("booking.submit", "Spara")
  |> g18n.add_translation("booking.cancel", "Avbryt")
  |> g18n.add_translation("booking.submitting", "Sparar bokning...")
  |> g18n.add_translation("booking.change", "Ändra bokning")
  |> g18n.add_translation("booking.unbook", "Avboka")
  |> g18n.add_translation("booking.confirm_unbook", "Ja, avboka")
  |> g18n.add_translation("list.search_placeholder", "Sök")
  |> g18n.add_translation("list.filter.all", "Alla")
  |> g18n.add_translation("list.tab.activities", "Aktiviteter")
  |> g18n.add_translation("list.tab.badbuss", "Badbuss")
  |> g18n.add_translation("list.tab.climbing_wall", "Klättervägg")
  |> g18n.add_translation("list.filter.favourites", "Favoriter")
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
  |> g18n.add_translation("list.retry", "Försök igen")
}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

/// A list-view row: a slim activity summary paired with the current user's
/// status for it. Built at view time from the summary cache + status dict.
type CardItem {
  CardItem(summary: ActivitySummary, status: ActivityStatus)
}

fn to_card_items(
  summaries: List(ActivitySummary),
  statuses: Dict(Uuid, ActivityStatus),
) -> List(CardItem) {
  list.map(summaries, fn(s) { CardItem(s, status_of(statuses, s.id)) })
}

/// The user's status for one activity; `NotInterested` when absent from the
/// (sparse) status dict.
fn status_of(statuses: Dict(Uuid, ActivityStatus), id: Uuid) -> ActivityStatus {
  case dict.get(statuses, id) {
    Ok(status) -> status
    Error(_) -> NotInterested
  }
}

/// Booked activities count as favourited too (the heart stays filled/locked).
fn is_favourited(status: ActivityStatus) -> Bool {
  case status {
    Booked(_) | Favourited -> True
    NotInterested -> False
  }
}

fn is_booked(status: ActivityStatus) -> Bool {
  case status {
    Booked(_) -> True
    Favourited | NotInterested -> False
  }
}

fn booking_of(status: ActivityStatus) -> Option(Booking) {
  case status {
    Booked(booking) -> Some(booking)
    Favourited | NotInterested -> None
  }
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

type BookingFormFields {
  BookingFormFields(
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

type BookingMode {
  BookingNew
  BookingEdit(booking_id: Uuid)
}

type BookingFormState {
  BookingClosed
  BookingOpen(
    form: Form(BookingFormFields),
    submit_error: Option(String),
    mode: BookingMode,
  )
  BookingSubmitting(mode: BookingMode)
  UnbookConfirming(booking_id: Uuid)
  UnbookSubmitting(booking_id: Uuid)
}

type RemoteData(a) {
  Loading
  Loaded(a)
  Failed(String)
}

type EditState {
  EditReady(
    activity: Activity,
    form: Form(ActivityForm),
    submit_error: Option(String),
  )
}

type ListTab {
  TabAll
  // Placeholder categories: label-only tabs, no data model yet.
  TabCategory(String)
  TabFavourites
}

type ListFilters {
  ListFilters(
    search: String,
    tab: ListTab,
    day: Option(calendar.Date),
    more_open: Bool,
    audiences: List(String),
    tags: List(String),
  )
}

fn default_filters() -> ListFilters {
  ListFilters(
    search: "",
    tab: TabAll,
    day: None,
    more_open: False,
    audiences: [],
    tags: [],
  )
}

/// Tabs in display order; index is used for the segmented control.
fn list_tabs() -> List(ListTab) {
  [
    TabAll,
    TabCategory("list.tab.badbuss"),
    TabCategory("list.tab.climbing_wall"),
    TabFavourites,
  ]
}

fn tab_index(tab: ListTab) -> Int {
  let indexed = list.index_map(list_tabs(), fn(t, i) { #(t, i) })
  case list.find(indexed, fn(pair) { pair.0 == tab }) {
    Ok(#(_, i)) -> i
    Error(_) -> 0
  }
}

fn tab_from_index(index: Int) -> ListTab {
  case list.drop(list_tabs(), index) {
    [tab, ..] -> tab
    [] -> TabAll
  }
}

type Page {
  ActivitiesListPage(filters: ListFilters)
  ActivityNewPage(form: Form(ActivityForm), submit_error: Option(String))
  ActivityDetailPage(id: Uuid, booking: BookingFormState)
  ActivityEditPage(id: Uuid, state: EditState)
  NotFoundPage
}

type Model {
  Model(
    page: Page,
    translator: Translator,
    logged_in: Bool,
    // Full activity catalogue (slim summaries), fetched once at startup.
    summaries: RemoteData(List(ActivitySummary)),
    // Full activities (with description), fetched lazily per detail view.
    details: Dict(Uuid, RemoteData(Activity)),
    // Sparse: present key => Booked/Favourited. Absent => NotInterested.
    statuses: Dict(Uuid, ActivityStatus),
  )
}

/// The cached detail for an activity, defaulting to `Loading` while a fetch is
/// expected but the cache has no entry yet.
fn detail_of(model: Model, id: Uuid) -> RemoteData(Activity) {
  case dict.get(model.details, id) {
    Ok(remote) -> remote
    Error(_) -> Loading
  }
}

/// Marks a detail page's activity as `Loading` in the cache when a fetch is
/// about to start, so the detail view shows a spinner instead of a flash of
/// "not found".
fn seed_detail_loading(
  details: Dict(Uuid, RemoteData(Activity)),
  page: Page,
) -> Dict(Uuid, RemoteData(Activity)) {
  case page {
    ActivityDetailPage(id, _) | ActivityEditPage(id, _) ->
      case dict.get(details, id) {
        Ok(Loaded(_)) -> details
        _ -> dict.insert(details, id, Loading)
      }
    _ -> details
  }
}

fn to_summary(a: Activity) -> ActivitySummary {
  model.ActivitySummary(
    id: a.id,
    title: a.title,
    max_attendees: a.max_attendees,
    start_time: a.start_time,
    end_time: a.end_time,
  )
}

fn map_loaded(
  remote: RemoteData(List(a)),
  f: fn(List(a)) -> List(a),
) -> RemoteData(List(a)) {
  case remote {
    Loaded(items) -> Loaded(f(items))
    Loading | Failed(_) -> remote
  }
}

/// Insert or replace a summary in the catalogue cache (no-op while loading).
fn upsert_summary(
  summaries: RemoteData(List(ActivitySummary)),
  summary: ActivitySummary,
) -> RemoteData(List(ActivitySummary)) {
  use items <- map_loaded(summaries)
  case list.any(items, fn(x) { x.id == summary.id }) {
    True ->
      list.map(items, fn(x) {
        case x.id == summary.id {
          True -> summary
          False -> x
        }
      })
    False -> [summary, ..items]
  }
}

fn remove_summary(
  summaries: RemoteData(List(ActivitySummary)),
  id: Uuid,
) -> RemoteData(List(ActivitySummary)) {
  use items <- map_loaded(summaries)
  list.filter(items, fn(x) { x.id != id })
}

fn new_booking_form() -> Form(BookingFormFields) {
  form.new({
    use group_free_text <- form.field("group_free_text", form.parse_string)
    use responsible_name <- form.field(
      "responsible_name",
      form.parse_string |> form.check_not_empty,
    )
    use phone_number <- form.field(
      "phone_number",
      form.parse_string |> form.check_not_empty,
    )
    use participant_count <- form.field("participant_count", form.parse_int)
    form.success(BookingFormFields(
      group_free_text:,
      responsible_name:,
      phone_number:,
      participant_count:,
    ))
  })
  |> form.add_string("participant_count", "1")
}

fn empty_booking_fields() -> BookingFormFields {
  BookingFormFields(
    group_free_text: "",
    responsible_name: "",
    phone_number: "",
    participant_count: 1,
  )
}

fn booking_form_from(b: Booking) -> Form(BookingFormFields) {
  new_booking_form()
  |> form.add_string("group_free_text", b.group_free_text)
  |> form.add_string("responsible_name", b.responsible_name)
  |> form.add_string("phone_number", b.phone_number)
  |> form.add_string("participant_count", int.to_string(b.participant_count))
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
  let logged_in = get_logged_in()
  let translator = translator_for(get_html_lang())

  let #(page, page_effect) = case modem.initial_uri() {
    Ok(uri) -> uri_to_page(uri, dict.new())
    Error(_) -> #(ActivitiesListPage(default_filters()), effect.none())
  }

  let model =
    Model(
      page:,
      translator:,
      logged_in:,
      summaries: Loading,
      details: seed_detail_loading(dict.new(), page),
      statuses: dict.new(),
    )

  let title_effect = case app_bar_title(translator, page) {
    Some(title) -> set_app_bar_title(title)
    None -> effect.none()
  }

  let status_effect = case logged_in {
    True -> fetch_statuses()
    False -> effect.none()
  }

  #(
    model,
    effect.batch([
      modem.init(OnRouteChange),
      observe_lang(),
      fetch_summaries(),
      page_effect,
      status_effect,
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
  ApiReturnedSummaries(Result(List(ActivitySummary), rsvp.Error))
  ApiReturnedActivity(Uuid, Result(Activity, rsvp.Error))
  ApiReturnedStatuses(Result(List(ActivityStatusEntry), rsvp.Error))
  ApiCreatedActivity(Result(Activity, rsvp.Error))
  ApiUpdatedActivity(Result(Activity, rsvp.Error))
  ApiDeletedActivity(Uuid, Result(Nil, rsvp.Error))
  ApiCreatedBooking(Result(Booking, rsvp.Error))
  ApiUpdatedBooking(Result(Booking, rsvp.Error))
  ApiDeletedBooking(Uuid, Uuid, Result(Nil, rsvp.Error))
  ApiToggledFavourite(Uuid, Bool, Result(Nil, rsvp.Error))
  // Form submissions
  UserSubmittedCreateForm(Result(ActivityForm, Form(ActivityForm)))
  UserSubmittedEditForm(Result(ActivityForm, Form(ActivityForm)))
  UserSubmittedBookingForm(Result(BookingFormFields, Form(BookingFormFields)))
  // User actions
  UserClickedEdit
  UserClickedDelete
  UserClickedCancelEdit
  UserClickedBook
  UserClickedCancelBooking
  UserClickedChangeBooking
  UserClickedUnbook
  UserClickedConfirmUnbook
  UserClickedCancelUnbook
  UserToggledFavourite(Uuid)
  UserClickedRetryLoad
  // List page filters
  UserSearchedActivities(String)
  UserSelectedTab(Int)
  UserSelectedDay(Option(calendar.Date))
  UserToggledMoreFilters
  UserToggledAudience(String)
  UserToggledTag(String)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnRouteChange(uri) -> {
      let #(page, page_effect) = uri_to_page(uri, model.details)
      let details = seed_detail_loading(model.details, page)
      let title_effect = case app_bar_title(model.translator, page) {
        Some(title) -> set_app_bar_title(title)
        None -> effect.none()
      }
      let nav_effect = notify_navigation(uri)
      #(
        Model(..model, page:, details:),
        effect.batch([page_effect, title_effect, nav_effect]),
      )
    }

    LangChanged(lang) -> {
      let translator = translator_for(lang)
      let title_effect = case app_bar_title(translator, model.page) {
        Some(title) -> set_app_bar_title(title)
        None -> effect.none()
      }
      #(Model(..model, translator:), title_effect)
    }

    ApiReturnedSummaries(result) -> {
      let summaries = case result {
        Ok(items) -> Loaded(items)
        Error(_) -> Failed("Failed to load activities")
      }
      #(Model(..model, summaries:), effect.none())
    }

    ApiReturnedActivity(id, result) -> {
      let entry = case result {
        Ok(activity) -> Loaded(activity)
        Error(_) -> Failed("Failed to load activity")
      }
      #(
        Model(..model, details: dict.insert(model.details, id, entry)),
        effect.none(),
      )
    }

    ApiReturnedStatuses(Ok(entries)) -> {
      let statuses =
        list.fold(entries, dict.new(), fn(acc, entry) {
          dict.insert(acc, entry.activity_id, entry.status)
        })
      #(Model(..model, statuses:), effect.none())
    }

    // Keep the prior status dict on failure.
    ApiReturnedStatuses(Error(_)) -> #(model, effect.none())

    ApiCreatedActivity(Ok(activity)) -> #(
      Model(
        ..model,
        summaries: upsert_summary(model.summaries, to_summary(activity)),
        details: dict.insert(model.details, activity.id, Loaded(activity)),
      ),
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

    ApiUpdatedActivity(Ok(activity)) -> {
      let page = case model.page {
        ActivityEditPage(id, _) ->
          ActivityEditPage(
            id,
            EditReady(activity, form_from_activity(activity), None),
          )
        other -> other
      }
      #(
        Model(
          ..model,
          summaries: upsert_summary(model.summaries, to_summary(activity)),
          details: dict.insert(model.details, activity.id, Loaded(activity)),
          page:,
        ),
        effect.none(),
      )
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

    ApiDeletedActivity(id, Ok(_)) -> #(
      Model(
        ..model,
        summaries: remove_summary(model.summaries, id),
        details: dict.delete(model.details, id),
        statuses: dict.delete(model.statuses, id),
      ),
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiDeletedActivity(_, Error(_)) ->
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

    UserSelectedTab(index) ->
      update_filters(model, fn(filters) {
        ListFilters(..filters, tab: tab_from_index(index))
      })

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

    UserClickedRetryLoad -> #(
      Model(..model, summaries: Loading),
      fetch_summaries(),
    )

    UserToggledFavourite(activity_id) ->
      // Only logged-in users have favourites; ignore otherwise.
      case model.logged_in {
        False -> #(model, effect.none())
        True ->
          case status_of(model.statuses, activity_id) {
            // Booked => heart is locked; can't unfavourite.
            Booked(_) -> #(model, effect.none())
            Favourited -> #(
              Model(..model, statuses: dict.delete(model.statuses, activity_id)),
              remove_favourite(activity_id),
            )
            NotInterested -> #(
              Model(
                ..model,
                statuses: dict.insert(model.statuses, activity_id, Favourited),
              ),
              add_favourite(activity_id),
            )
          }
      }

    ApiToggledFavourite(activity_id, intended_favourited, Error(_)) -> {
      // Revert the optimistic change: undo an add, restore a removal.
      let statuses = case intended_favourited {
        True -> dict.delete(model.statuses, activity_id)
        False -> dict.insert(model.statuses, activity_id, Favourited)
      }
      #(Model(..model, statuses:), effect.none())
    }

    ApiToggledFavourite(_, _, Ok(_)) -> #(model, effect.none())

    UserClickedBook ->
      case model.page {
        ActivityDetailPage(id, BookingClosed) ->
          case detail_of(model, id) {
            Loaded(activity) ->
              case
                is_booked(status_of(model.statuses, id)),
                activity.max_attendees
              {
                True, _ -> #(model, effect.none())
                False, Some(_) -> #(
                  Model(
                    ..model,
                    page: ActivityDetailPage(
                      id,
                      BookingOpen(new_booking_form(), None, BookingNew),
                    ),
                  ),
                  effect.none(),
                )
                False, None -> #(
                  Model(
                    ..model,
                    page: ActivityDetailPage(id, BookingSubmitting(BookingNew)),
                  ),
                  create_booking(id, empty_booking_fields()),
                )
              }
            _ -> #(model, effect.none())
          }
        _ -> #(model, effect.none())
      }

    UserClickedChangeBooking ->
      case model.page {
        ActivityDetailPage(id, _) ->
          case booking_of(status_of(model.statuses, id)) {
            Some(booking) -> #(
              Model(
                ..model,
                page: ActivityDetailPage(
                  id,
                  BookingOpen(
                    booking_form_from(booking),
                    None,
                    BookingEdit(booking.id),
                  ),
                ),
              ),
              effect.none(),
            )
            None -> #(model, effect.none())
          }
        _ -> #(model, effect.none())
      }

    UserClickedUnbook ->
      case model.page {
        ActivityDetailPage(id, _) ->
          case booking_of(status_of(model.statuses, id)) {
            Some(booking) -> #(
              Model(
                ..model,
                page: ActivityDetailPage(id, UnbookConfirming(booking.id)),
              ),
              effect.none(),
            )
            None -> #(model, effect.none())
          }
        _ -> #(model, effect.none())
      }

    UserClickedCancelUnbook ->
      case model.page {
        ActivityDetailPage(id, _) -> #(
          Model(..model, page: ActivityDetailPage(id, BookingClosed)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserClickedConfirmUnbook ->
      case model.page {
        ActivityDetailPage(id, UnbookConfirming(booking_id)) -> #(
          Model(
            ..model,
            page: ActivityDetailPage(id, UnbookSubmitting(booking_id)),
          ),
          delete_booking(id, booking_id),
        )
        _ -> #(model, effect.none())
      }

    UserClickedCancelBooking ->
      case model.page {
        ActivityDetailPage(id, _) -> #(
          Model(..model, page: ActivityDetailPage(id, BookingClosed)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedBookingForm(Ok(fields)) ->
      case model.page {
        ActivityDetailPage(id, BookingOpen(_, _, mode)) -> {
          let effect_ = case mode {
            BookingNew -> create_booking(id, fields)
            BookingEdit(booking_id) -> update_booking(booking_id, fields)
          }
          #(
            Model(
              ..model,
              page: ActivityDetailPage(id, BookingSubmitting(mode)),
            ),
            effect_,
          )
        }
        _ -> #(model, effect.none())
      }

    UserSubmittedBookingForm(Error(f)) ->
      case model.page {
        ActivityDetailPage(id, BookingOpen(_, _, mode)) -> #(
          Model(
            ..model,
            page: ActivityDetailPage(id, BookingOpen(f, None, mode)),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    ApiCreatedBooking(Ok(booking)) -> {
      // Server auto-favourites on booking, so a single Booked entry captures
      // both the booking and the favourite.
      let statuses =
        dict.insert(model.statuses, booking.activity_id, Booked(booking))
      let page = case model.page {
        ActivityDetailPage(id, _) -> ActivityDetailPage(id, BookingClosed)
        other -> other
      }
      #(Model(..model, statuses:, page:), effect.none())
    }

    ApiCreatedBooking(Error(_)) ->
      case model.page {
        ActivityDetailPage(id, BookingSubmitting(mode)) -> #(
          Model(
            ..model,
            page: ActivityDetailPage(
              id,
              BookingOpen(
                new_booking_form(),
                Some("Failed to create booking"),
                mode,
              ),
            ),
          ),
          effect.none(),
        )
        ActivityDetailPage(id, _) -> #(
          Model(..model, page: ActivityDetailPage(id, BookingClosed)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    ApiUpdatedBooking(Ok(booking)) -> {
      let statuses =
        dict.insert(model.statuses, booking.activity_id, Booked(booking))
      let page = case model.page {
        ActivityDetailPage(id, _) -> ActivityDetailPage(id, BookingClosed)
        other -> other
      }
      #(Model(..model, statuses:, page:), effect.none())
    }

    ApiUpdatedBooking(Error(_)) ->
      case model.page {
        ActivityDetailPage(id, BookingSubmitting(mode)) -> #(
          Model(
            ..model,
            page: ActivityDetailPage(
              id,
              BookingOpen(
                new_booking_form(),
                Some("Failed to update booking"),
                mode,
              ),
            ),
          ),
          effect.none(),
        )
        ActivityDetailPage(id, _) -> #(
          Model(..model, page: ActivityDetailPage(id, BookingClosed)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    ApiDeletedBooking(activity_id, _booking_id, Ok(_)) -> {
      // Unbooking keeps the favourite server-side, so downgrade to Favourited
      // rather than removing the status entirely.
      let statuses = dict.insert(model.statuses, activity_id, Favourited)
      let page = case model.page {
        ActivityDetailPage(id, _) -> ActivityDetailPage(id, BookingClosed)
        other -> other
      }
      #(Model(..model, statuses:, page:), effect.none())
    }

    ApiDeletedBooking(_, _, Error(_)) ->
      case model.page {
        ActivityDetailPage(id, _) -> #(
          Model(..model, page: ActivityDetailPage(id, BookingClosed)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
  }
}

fn update_filters(
  model: Model,
  f: fn(ListFilters) -> ListFilters,
) -> #(Model, Effect(Msg)) {
  case model.page {
    ActivitiesListPage(filters) -> #(
      Model(..model, page: ActivitiesListPage(f(filters))),
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

@external(javascript, "./client_ffi.mjs", "post_app_bar_title")
fn post_app_bar_title(title: String) -> Nil

@external(javascript, "./client_ffi.mjs", "post_navigation")
fn post_navigation(url: String) -> Nil

@external(javascript, "./client_ffi.mjs", "get_html_lang")
fn get_html_lang() -> String

@external(javascript, "./client_ffi.mjs", "get_logged_in")
fn get_logged_in() -> Bool

@external(javascript, "./client_ffi.mjs", "observe_html_lang")
fn observe_html_lang(callback: fn(String) -> Nil) -> Nil

fn set_app_bar_title(title: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { post_app_bar_title(title) })
}

fn notify_navigation(u: Uri) -> Effect(msg) {
  effect.from(fn(_dispatch) { post_navigation(relative_url(u)) })
}

/// Drops scheme, userinfo, host, and port from a URI, leaving just the
/// path / query / fragment — what the parent frame needs to mirror an
/// in-iframe SPA navigation.
pub fn relative_url(u: Uri) -> String {
  uri.Uri(..u, scheme: None, userinfo: None, host: None, port: None)
  |> uri.to_string
}

fn observe_lang() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    observe_html_lang(fn(lang) { dispatch(LangChanged(lang)) })
  })
}

fn fetch_summaries() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activities",
    rsvp.expect_json(model.activity_summaries_decoder(), ApiReturnedSummaries),
  )
}

fn fetch_activity(id: Uuid) -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activities/" <> uuid.to_string(id),
    rsvp.expect_json(model.activity_decoder(), fn(result) {
      ApiReturnedActivity(id, result)
    }),
  )
}

fn fetch_statuses() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/statuses/me",
    rsvp.expect_json(model.activity_statuses_decoder(), ApiReturnedStatuses),
  )
}

fn add_favourite(activity_id: Uuid) -> Effect(Msg) {
  rsvp.put(
    api_prefix
      <> "/api/activities/"
      <> uuid.to_string(activity_id)
      <> "/favourite",
    json.null(),
    rsvp.expect_any_response(fn(result) {
      case result {
        Ok(_) -> ApiToggledFavourite(activity_id, True, Ok(Nil))
        Error(err) -> ApiToggledFavourite(activity_id, True, Error(err))
      }
    }),
  )
}

fn remove_favourite(activity_id: Uuid) -> Effect(Msg) {
  rsvp.delete(
    api_prefix
      <> "/api/activities/"
      <> uuid.to_string(activity_id)
      <> "/favourite",
    json.null(),
    rsvp.expect_any_response(fn(result) {
      case result {
        Ok(_) -> ApiToggledFavourite(activity_id, False, Ok(Nil))
        Error(err) -> ApiToggledFavourite(activity_id, False, Error(err))
      }
    }),
  )
}

fn create_booking(activity_id: Uuid, fields: BookingFormFields) -> Effect(Msg) {
  rsvp.post(
    api_prefix
      <> "/api/activities/"
      <> uuid.to_string(activity_id)
      <> "/bookings",
    booking_form_to_json(fields),
    rsvp.expect_json(model.booking_decoder(), ApiCreatedBooking),
  )
}

fn update_booking(booking_id: Uuid, fields: BookingFormFields) -> Effect(Msg) {
  rsvp.put(
    api_prefix <> "/api/bookings/" <> uuid.to_string(booking_id),
    booking_form_to_json(fields),
    rsvp.expect_json(model.booking_decoder(), ApiUpdatedBooking),
  )
}

fn delete_booking(activity_id: Uuid, booking_id: Uuid) -> Effect(Msg) {
  rsvp.delete(
    api_prefix <> "/api/bookings/" <> uuid.to_string(booking_id),
    json.null(),
    rsvp.expect_any_response(fn(result) {
      case result {
        Ok(_) -> ApiDeletedBooking(activity_id, booking_id, Ok(Nil))
        Error(err) -> ApiDeletedBooking(activity_id, booking_id, Error(err))
      }
    }),
  )
}

fn booking_form_to_json(fields: BookingFormFields) -> json.Json {
  json.object([
    #("group_free_text", json.string(fields.group_free_text)),
    #("responsible_name", json.string(fields.responsible_name)),
    #("phone_number", json.string(fields.phone_number)),
    #("participant_count", json.int(fields.participant_count)),
  ])
}

fn create_activity(af: ActivityForm) -> Effect(Msg) {
  rsvp.post(
    api_prefix <> "/api/activities",
    activity_form_to_json(af),
    rsvp.expect_json(model.activity_decoder(), ApiCreatedActivity),
  )
}

fn update_activity(id: Uuid, af: ActivityForm) -> Effect(Msg) {
  rsvp.put(
    api_prefix <> "/api/activities/" <> uuid.to_string(id),
    activity_form_to_json(af),
    rsvp.expect_json(model.activity_decoder(), ApiUpdatedActivity),
  )
}

fn delete_activity(id: Uuid) -> Effect(Msg) {
  rsvp.delete(
    api_prefix <> "/api/activities/" <> uuid.to_string(id),
    json.null(),
    rsvp.expect_any_response(fn(result) {
      case result {
        Ok(_) -> ApiDeletedActivity(id, Ok(Nil))
        Error(err) -> ApiDeletedActivity(id, Error(err))
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

fn uri_to_page(
  uri: Uri,
  details: Dict(Uuid, RemoteData(Activity)),
) -> #(Page, Effect(Msg)) {
  case uri.path_segments(uri.path) |> list.drop(2) {
    ["activities"] | [] -> #(
      ActivitiesListPage(default_filters()),
      effect.none(),
    )
    ["activities", "new"] -> #(
      ActivityNewPage(activity_form(), None),
      effect.none(),
    )
    ["activities", id_str] ->
      case uuid.from_string(id_str) {
        Ok(id) -> {
          // Reuse the cached activity if present; otherwise fetch it lazily.
          let effect_ = case dict.get(details, id) {
            Ok(Loaded(_)) -> effect.none()
            _ -> fetch_activity(id)
          }
          #(ActivityDetailPage(id, BookingClosed), effect_)
        }
        Error(_) -> #(NotFoundPage, effect.none())
      }
    _ -> #(NotFoundPage, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.page {
    ActivitiesListPage(filters) ->
      view_activities_list(
        model.translator,
        model.summaries,
        model.statuses,
        filters,
      )
    ActivityNewPage(form, submit_error) -> view_activity_new(form, submit_error)
    ActivityDetailPage(id, booking) ->
      view_activity_detail(
        model.translator,
        detail_of(model, id),
        status_of(model.statuses, id),
        booking,
      )
    ActivityEditPage(_, _) -> view_not_found()
    NotFoundPage -> view_not_found()
  }
}

fn view_activities_list(
  translator: Translator,
  summaries: RemoteData(List(ActivitySummary)),
  statuses: Dict(Uuid, ActivityStatus),
  filters: ListFilters,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }

  html.div([attribute.class("flex flex-col gap-3 p-4")], [
    view_list_top_bar(translator, filters, summaries),
    case filters.more_open {
      True -> view_more_filters_panel(translator, filters)
      False -> element.none()
    },
    case summaries {
      Loading -> component.scout_loader(t("activity.loading"))
      Failed(err) ->
        html.div([attribute.class("py-6 flex flex-col items-center gap-3")], [
          component.error_banner(err),
          component.scout_button_action(
            t("list.retry"),
            "primary",
            UserClickedRetryLoad,
          ),
        ])
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
      Loaded(items) ->
        view_grouped_activities(
          translator,
          to_card_items(items, statuses),
          filters,
        )
    },
  ])
}

fn view_list_top_bar(
  translator: Translator,
  filters: ListFilters,
  summaries: RemoteData(List(ActivitySummary)),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let dates = case summaries {
    Loaded(items) -> camp_dates(items)
    _ -> []
  }
  let tab_labels = list.map(list_tabs(), fn(tab) { tab_label(translator, tab) })
  html.div(
    [
      attribute.class(
        "flex flex-col gap-2 bg-white rounded-lg border border-gray-200 p-3",
      ),
    ],
    [
      component.scout_segmented_control(
        tab_index(filters.tab),
        tab_labels,
        UserSelectedTab,
        [attribute.class("w-full")],
      ),
      component.scout_input_search(
        filters.search,
        t("list.search_placeholder"),
        UserSearchedActivities,
      ),
      html.div([attribute.class("flex items-center gap-2")], [
        view_day_select(translator, filters.day, dates),
        component.filter_pill_icon(
          t("list.filter.more"),
          icons.filter,
          filters.more_open,
          UserToggledMoreFilters,
        ),
      ]),
    ],
  )
}

fn tab_label(translator: Translator, tab: ListTab) -> String {
  case tab {
    TabAll -> g18n.translate(translator, "list.tab.activities")
    TabCategory(key) -> g18n.translate(translator, key)
    TabFavourites -> g18n.translate(translator, "list.filter.favourites")
  }
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
      attribute.class("flex-1 min-w-0"),
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
  items: List(CardItem),
  filters: ListFilters,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let filtered =
    apply_filters(items, filters)
    |> list.sort(fn(a, b) {
      timestamp.compare(a.summary.start_time, b.summary.start_time)
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
  items: List(CardItem),
) -> List(#(#(calendar.Date, TimeBucket), List(CardItem))) {
  let key_for = fn(item: CardItem) {
    #(date_of(item.summary.start_time), bucket_for(item.summary.start_time))
  }
  let grouped = list.group(items, by: key_for)
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
        timestamp.compare(a.summary.start_time, b.summary.start_time)
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
  items: List(CardItem),
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
      list.map(items, fn(item) { view_activity_card(translator, date, item) }),
    ),
  ])
}

fn view_activity_card(
  translator: Translator,
  section_date: calendar.Date,
  item: CardItem,
) -> Element(Msg) {
  let summary = item.summary
  let id = uuid.to_string(summary.id)
  let time =
    view_card_time(
      translator,
      summary.start_time,
      summary.end_time,
      section_date,
    )
  let location = mock_location(summary.id)
  let spots_text = case summary.max_attendees {
    Some(_) -> {
      let spots = mock_spots_remaining(summary)
      Some(g18n.translate_plural(translator, "activity.spots_remaining", spots))
    }
    None -> None
  }
  let status = card_status(translator, summary, item.status)
  component.activity_card(
    api_prefix <> "/activities/" <> id,
    summary.title,
    status,
    is_favourited(item.status),
    UserToggledFavourite(summary.id),
    time,
    location,
    spots_text,
  )
}

/// Maps the user's status + capacity to the card's status badge.
fn card_status(
  translator: Translator,
  summary: ActivitySummary,
  status: ActivityStatus,
) -> component.CardStatus {
  case is_booked(status), summary.max_attendees {
    True, _ ->
      component.StatusBooked(g18n.translate(translator, "activity.booked"))
    False, Some(_) ->
      component.StatusNeedsBooking(g18n.translate(
        translator,
        "activity.needs_booking",
      ))
    False, None -> component.StatusNone
  }
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
  status: ActivityStatus,
  booking: BookingFormState,
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
    Loaded(activity) ->
      view_activity_detail_loaded(translator, activity, status, booking)
  }
}

fn view_activity_detail_loaded(
  translator: Translator,
  activity: Activity,
  status: ActivityStatus,
  booking: BookingFormState,
) -> Element(Msg) {
  let heart_btn =
    component.heart_button(
      is_favourited(status),
      is_booked(status),
      UserToggledFavourite(activity.id),
      False,
    )
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
            html.div([attribute.class("flex-1 flex pt-1 min-w-0")], [
              html.h1(
                [
                  attribute.class(
                    "text-heading-xs hyphens-auto break-words text-balance min-w-0",
                  ),
                ],
                [element.text(activity.title)],
              ),
            ]),
            html.div([attribute.class("flex flex-col gap-2 items-end")], [
              {
                let #(primary, secondary) =
                  view_detail_actions(
                    translator,
                    activity,
                    is_booked(status),
                    booking,
                  )
                // Mobile: primary on its own row, secondary + heart on a second
                // row. Desktop (sm+): inline together, right-aligned.
                html.div(
                  [
                    attribute.class(
                      "flex flex-col items-end gap-2 sm:flex-row sm:items-center sm:flex-wrap sm:justify-end",
                    ),
                  ],
                  [
                    primary,
                    html.div([attribute.class("flex items-center gap-2")], [
                      secondary,
                      heart_btn,
                    ]),
                  ],
                )
              },
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
        view_booking_form_section(translator, booking),
      ],
    ),
  ])
}

/// Splits the detail-page actions into a `#(primary, secondary)` pair so the
/// caller can place the secondary element next to the heart and the primary
/// element on its own row on mobile.
fn view_detail_actions(
  translator: Translator,
  activity: Activity,
  booked: Bool,
  booking: BookingFormState,
) -> #(Element(Msg), Element(Msg)) {
  case booked, booking {
    // While the booking form is open or submitting, hide the action row —
    // the form itself provides Submit/Cancel.
    _, BookingOpen(_, _, _) -> #(element.none(), element.none())
    _, BookingSubmitting(_) -> #(element.none(), element.none())

    // Booked activity: ask the user to confirm before deleting their booking.
    True, UnbookConfirming(_) -> #(
      component.scout_button_action(
        g18n.translate(translator, "booking.confirm_unbook"),
        "danger",
        UserClickedConfirmUnbook,
      ),
      component.scout_button_action(
        g18n.translate(translator, "booking.cancel"),
        "outlined",
        UserClickedCancelUnbook,
      ),
    )

    True, UnbookSubmitting(_) -> #(
      component.scout_loader(g18n.translate(translator, "booking.submitting")),
      element.none(),
    )

    // Booked, no special state: offer "Ändra bokning" + "Avboka".
    True, BookingClosed -> #(
      component.scout_button_action(
        g18n.translate(translator, "booking.change"),
        "primary",
        UserClickedChangeBooking,
      ),
      component.scout_button_action(
        g18n.translate(translator, "booking.unbook"),
        "danger",
        UserClickedUnbook,
      ),
    )

    // Not booked: only the "Boka" button if the activity has capacity.
    False, _ ->
      case activity.max_attendees {
        Some(_) -> #(
          component.scout_button_action(
            g18n.translate(translator, "activity.book"),
            "primary",
            UserClickedBook,
          ),
          element.none(),
        )
        None -> #(element.none(), element.none())
      }
  }
}

fn view_booking_form_section(
  translator: Translator,
  booking: BookingFormState,
) -> Element(Msg) {
  case booking {
    BookingClosed -> element.none()
    UnbookConfirming(_) -> element.none()
    UnbookSubmitting(_) -> element.none()
    BookingSubmitting(_) ->
      html.div([attribute.class("flex justify-center py-4")], [
        component.scout_loader(g18n.translate(translator, "booking.submitting")),
      ])
    BookingOpen(form, submit_error, _) -> {
      let submitted = fn(values) {
        form
        |> form.add_values(values)
        |> form.run
        |> UserSubmittedBookingForm
      }
      html.form([event.on_submit(submitted)], [
        component.scout_card([
          html.div([attribute.class("flex flex-col gap-2")], [
            case submit_error {
              Some(err) -> component.error_banner(err)
              None -> element.none()
            },
            component.scout_form_field(
              form,
              g18n.translate(translator, "booking.responsible_name"),
              "text",
              "responsible_name",
            ),
            component.scout_form_field(
              form,
              g18n.translate(translator, "booking.phone_number"),
              "tel",
              "phone_number",
            ),
            component.scout_form_field(
              form,
              g18n.translate(translator, "booking.group_free_text"),
              "text",
              "group_free_text",
            ),
            component.scout_form_field(
              form,
              g18n.translate(translator, "booking.participant_count"),
              "number",
              "participant_count",
            ),
            html.div([attribute.class("flex gap-2 justify-end")], [
              component.scout_button_action(
                g18n.translate(translator, "booking.cancel"),
                "outlined",
                UserClickedCancelBooking,
              ),
              element.element(
                "scout-button",
                [
                  attribute.attribute("variant", "primary"),
                  attribute.attribute("type", "submit"),
                ],
                [
                  element.text(g18n.translate(translator, "booking.submit")),
                ],
              ),
            ]),
          ]),
        ]),
      ])
    }
  }
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

fn mock_spots_remaining(summary: ActivitySummary) -> Int {
  case summary.max_attendees {
    Some(max) -> {
      let taken = id_seed(summary.id) % { max + 1 }
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

fn apply_filters(items: List(CardItem), f: ListFilters) -> List(CardItem) {
  let needle = string.lowercase(string.trim(f.search))
  use item <- list.filter(items)
  let summary = item.summary
  let title_match = case needle {
    "" -> True
    _ -> string.contains(string.lowercase(summary.title), needle)
  }
  let day_match = case f.day {
    None -> True
    Some(date) -> date_of(summary.start_time) == date
  }
  let favourite_match = case f.tab {
    TabFavourites -> is_favourited(item.status)
    // TODO: filter by category once a real category data model exists.
    TabAll | TabCategory(_) -> True
  }
  let audience_match = case f.audiences {
    [] -> True
    selected -> lists_intersect(mock_audiences(summary.id), selected)
  }
  let tag_match = case f.tags {
    [] -> True
    selected -> lists_intersect(mock_tags(summary.id), selected)
  }
  title_match && day_match && favourite_match && audience_match && tag_match
}

fn camp_dates(summaries: List(ActivitySummary)) -> List(calendar.Date) {
  summaries
  |> list.map(fn(summary) { date_of(summary.start_time) })
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
