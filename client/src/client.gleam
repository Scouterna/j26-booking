import component
import formal/form.{type Form}
import g18n.{type Translator}
import g18n/locale
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
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
import lustre/element/keyed
import lustre/event
import modem
import rsvp
import shared/model.{
  type Activity, type ActivitySpots, type ActivityStatus,
  type ActivityStatusEntry, type ActivitySummary, type ActivityTag, type Booking,
  type Location, type TargetGroup, Booked, Favourited, NotInterested,
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
  |> g18n.add_translation("activity.spots_unknown", "Spots remaining: unknown")
  |> g18n.add_translation("activity.time", "Time")
  |> g18n.add_translation("activity.date_range_separator", "to")
  |> g18n.add_translation("activity.location", "Location")
  |> g18n.add_translation("app_bar.activities_list", "Activities")
  |> g18n.add_translation("app_bar.activity_detail", "Activity")
  |> g18n.add_translation("app_bar.activity_new", "Create activity")
  |> g18n.add_translation("activity.booked", "Booked")
  |> g18n.add_translation("activity.needs_booking", "Needs booking")
  |> g18n.add_translation("activity.show_bookings", "Show bookings")
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
  |> g18n.add_translation("list.tab.beach_bus", "Beach bus")
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
  |> g18n.add_translation("error.heading", "Something went wrong")
  |> g18n.add_translation("error.load_activities", "Failed to load activities")
  |> g18n.add_translation("error.load_activity", "Failed to load activity")
  |> g18n.add_translation("error.create_activity", "Failed to create activity")
  |> g18n.add_translation("error.update_activity", "Failed to update activity")
  |> g18n.add_translation("error.delete_activity", "Failed to delete activity")
  |> g18n.add_translation("error.create_booking", "Failed to create booking")
  |> g18n.add_translation("error.update_booking", "Failed to update booking")
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
  |> g18n.add_translation("activity.spots_unknown", "Platser kvar: okänt")
  |> g18n.add_translation("activity.time", "Tid")
  |> g18n.add_translation("activity.date_range_separator", "till")
  |> g18n.add_translation("activity.location", "Plats")
  |> g18n.add_translation("app_bar.activities_list", "Spontanaktiviteter")
  |> g18n.add_translation("app_bar.activity_detail", "Aktivitet")
  |> g18n.add_translation("app_bar.activity_new", "Skapa aktivitet")
  |> g18n.add_translation("activity.booked", "Bokad")
  |> g18n.add_translation("activity.needs_booking", "Behöver bokas")
  |> g18n.add_translation("activity.show_bookings", "Visa bokningar")
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
  |> g18n.add_translation("list.tab.beach_bus", "Badbuss")
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
  |> g18n.add_translation("error.heading", "Något gick fel")
  |> g18n.add_translation(
    "error.load_activities",
    "Kunde inte ladda aktiviteter",
  )
  |> g18n.add_translation("error.load_activity", "Kunde inte ladda aktiviteten")
  |> g18n.add_translation(
    "error.create_activity",
    "Kunde inte skapa aktiviteten",
  )
  |> g18n.add_translation(
    "error.update_activity",
    "Kunde inte uppdatera aktiviteten",
  )
  |> g18n.add_translation(
    "error.delete_activity",
    "Kunde inte ta bort aktiviteten",
  )
  |> g18n.add_translation("error.create_booking", "Kunde inte skapa bokningen")
  |> g18n.add_translation(
    "error.update_booking",
    "Kunde inte uppdatera bokningen",
  )
}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

/// A list-view row: a slim activity summary paired with the current user's
/// status for it and its booked-spot count. Built at view time from the summary
/// cache + status dict + spots dict. `spots_booked` is `None` when the count is
/// unknown (not fetched / offline).
pub type CardItem {
  CardItem(
    summary: ActivitySummary,
    status: ActivityStatus,
    spots_booked: Option(Int),
  )
}

pub fn to_card_items(
  summaries: List(ActivitySummary),
  statuses: Dict(Uuid, ActivityStatus),
  spots: Dict(Uuid, Int),
) -> List(CardItem) {
  list.map(summaries, fn(s) {
    CardItem(
      s,
      status_of(statuses, s.id),
      dict.get(spots, s.id) |> option.from_result,
    )
  })
}

/// The user's status for one activity; `NotInterested` when absent from the
/// (sparse) status dict.
pub fn status_of(
  statuses: Dict(Uuid, ActivityStatus),
  id: Uuid,
) -> ActivityStatus {
  case dict.get(statuses, id) {
    Ok(status) -> status
    Error(_) -> NotInterested
  }
}

/// Booked activities count as favourited too (the heart stays filled/locked).
pub fn is_favourited(status: ActivityStatus) -> Bool {
  case status {
    Booked(_) | Favourited -> True
    NotInterested -> False
  }
}

pub fn is_booked(status: ActivityStatus) -> Bool {
  case status {
    Booked(_) -> True
    Favourited | NotInterested -> False
  }
}

pub fn booking_of(status: ActivityStatus) -> Option(Booking) {
  case status {
    Booked(booking) -> Some(booking)
    Favourited | NotInterested -> None
  }
}

/// The list endpoint backing a browse selection. Tabs map to a source; the
/// Favourites tab's `SourceFavourites` only hydrates the cache + drives loading
/// state — its membership is derived from `statuses`, not from this list.
pub type ActivityListSource {
  SourceActivities
  SourceBeachBus
  SourceClimbingWall
  SourceFavourites
}

pub type ActivityForm {
  ActivityForm(
    title: String,
    title_en: String,
    description: String,
    description_en: String,
    max_attendees: Option(Int),
    start_time: #(calendar.Date, calendar.TimeOfDay),
    end_time: #(calendar.Date, calendar.TimeOfDay),
  )
}

pub type BookingFormFields {
  BookingFormFields(
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

pub type BookingMode {
  BookingNew
  BookingEdit(booking_id: Uuid)
}

pub type BookingFormState {
  BookingClosed
  BookingOpen(
    form: Form(BookingFormFields),
    submit_error: Option(AppError),
    mode: BookingMode,
  )
  BookingSubmitting(mode: BookingMode)
  UnbookConfirming(booking_id: Uuid)
  UnbookSubmitting(booking_id: Uuid)
}

pub type RemoteData(a) {
  NotAsked
  Loading
  Loaded(a)
  Failed(AppError)
}

/// A user-facing error. Stored (rather than a pre-translated string) so the view
/// can localize it at render time — this way an error surfaced in one language
/// re-renders correctly if the user switches language before dismissing it.
pub type AppError {
  LoadActivitiesFailed
  LoadActivityFailed
  CreateActivityFailed
  UpdateActivityFailed
  DeleteActivityFailed
  CreateBookingFailed
  UpdateBookingFailed
}

fn app_error_key(error: AppError) -> String {
  case error {
    LoadActivitiesFailed -> "error.load_activities"
    LoadActivityFailed -> "error.load_activity"
    CreateActivityFailed -> "error.create_activity"
    UpdateActivityFailed -> "error.update_activity"
    DeleteActivityFailed -> "error.delete_activity"
    CreateBookingFailed -> "error.create_booking"
    UpdateBookingFailed -> "error.update_booking"
  }
}

pub type EditState {
  EditReady(
    activity: Activity,
    form: Form(ActivityForm),
    submit_error: Option(AppError),
    /// Working selection of tag ids, seeded from the activity and toggled in the
    /// edit form. Sent as-is on save (the server re-syncs to exactly this set).
    tags: List(Uuid),
    /// Working selection of target groups, seeded from the activity.
    target_groups: List(TargetGroup),
  )
}

pub type ActivitiesFilterTab {
  TabActivities
  TabBeachBus
  TabClimbingWall
  TabFavourites
}

pub type ListFilters {
  ListFilters(
    search: String,
    tab: ActivitiesFilterTab,
    day: Option(calendar.Date),
    more_open: Bool,
    target_groups: List(TargetGroup),
    tags: List(Uuid),
  )
}

pub fn default_filters() -> ListFilters {
  ListFilters(
    search: "",
    tab: TabActivities,
    day: None,
    more_open: False,
    target_groups: [],
    tags: [],
  )
}

/// Tabs in display order; index is used for the segmented control.
fn list_tabs() -> List(ActivitiesFilterTab) {
  [TabActivities, TabBeachBus, TabClimbingWall, TabFavourites]
}

pub fn tab_index(tab: ActivitiesFilterTab) -> Int {
  let indexed = list.index_map(list_tabs(), fn(t, i) { #(t, i) })
  case list.find(indexed, fn(pair) { pair.0 == tab }) {
    Ok(#(_, i)) -> i
    Error(_) -> 0
  }
}

pub fn tab_from_index(index: Int) -> ActivitiesFilterTab {
  case list.drop(list_tabs(), index) {
    [tab, ..] -> tab
    [] -> TabActivities
  }
}

pub type Page {
  ActivitiesListPage(filters: ListFilters)
  ActivityNewPage(
    form: Form(ActivityForm),
    submit_error: Option(AppError),
    /// Working selection of tag ids toggled in the create form.
    tags: List(Uuid),
    /// Working selection of target groups toggled in the create form.
    target_groups: List(TargetGroup),
  )
  ActivityDetailPage(id: Uuid, booking: BookingFormState)
  ActivityEditPage(id: Uuid, state: EditState)
  NotFoundPage
}

/// The detail-only fields of an activity — everything NOT already carried by
/// its `ActivitySummary`. Fetched lazily when a detail page opens and cached in
/// `Model.details`, keyed by activity id. Storing only these fields (rather than
/// a full `Activity`) keeps the summary in exactly one place (`Model.activities`),
/// so a list refetch can never leave an open detail view showing stale summary
/// fields.
pub type ActivityDetail {
  ActivityDetail(
    description: model.BilingualString,
    location: Option(Location),
    tags: List(Uuid),
    target_groups: List(TargetGroup),
  )
}

pub type Model {
  Model(
    page: Page,
    translator: Translator,
    // Entity cache: one slim summary per activity, hydrated/overwritten by
    // EVERY list response (browse pages, beach-bus, climbing-wall, favourited).
    activities: Dict(Uuid, ActivitySummary),
    // Ordered id windows per browse tab — define each tab's membership + order.
    activities_ids: RemoteData(List(Uuid)),
    beach_bus_ids: RemoteData(List(Uuid)),
    climbing_wall_ids: RemoteData(List(Uuid)),
    // Drives the Favourites tab's /api/favourited-activities fetch state and
    // cache hydration. Membership is DERIVED from `statuses`, not this list.
    favourited: RemoteData(List(Uuid)),
    // Detail-only fields (description + full location), fetched lazily per
    // detail view. Composed with the summary from `activities` at read time.
    details: Dict(Uuid, RemoteData(ActivityDetail)),
    // Sparse: present key => Booked/Favourited. Absent => NotInterested
    // (also the state for anonymous users: `/api/statuses/me` 401s and the
    // dict stays empty).
    statuses: Dict(Uuid, ActivityStatus),
    // Booked-spot counts per activity, fetched separately from the (cacheable)
    // activity metadata because they change far more often. A MISSING key means
    // UNKNOWN (not fetched / offline), not zero — so cached cards with no count
    // render "unknown" rather than falsely claiming full availability.
    spots: Dict(Uuid, Int),
    // Activity tag vocabulary, keyed by id, fetched once from /api/activity-tags.
    // Used to resolve the tag ids carried on activities into labels. Empty until
    // loaded (and if the fetch fails), in which case tag chips simply don't show.
    activity_tags: Dict(Uuid, ActivityTag),
    // The current user's roles, gating manage-only UI (e.g. viewing bookings).
    roles: List(Role),
  )
}

/// Access roles the client gates UI on, parsed from the user's Keycloak roles
/// on the `j26-booking` client. Only roles the UI acts on are modelled; the
/// string matches the server's `web.Role` (`ActivitiesManage`).
pub type Role {
  ManageActivities
}

fn role_from_string(raw: String) -> Result(Role, Nil) {
  case raw {
    "activities:manage" -> Ok(ManageActivities)
    _ -> Error(Nil)
  }
}

/// The current user's roles.
///
/// TODO(auth): the server already authenticates the user and knows their roles
/// (`web.Role` from `resource_access.j26-booking.roles`), but does not yet
/// expose them to the client. Wire this to a small endpoint (e.g. extend
/// `/api/statuses/me` or add `/api/me`) instead of hardcoding. Hardcoded here so
/// the role-gated UI works ahead of that; swap the list to `[]` to preview the
/// no-authority view.
fn initial_roles() -> List(Role) {
  ["activities:manage"] |> list.filter_map(role_from_string)
}

fn can_manage_activities(model: Model) -> Bool {
  list.contains(model.roles, ManageActivities)
}

pub fn tab_source(tab: ActivitiesFilterTab) -> ActivityListSource {
  case tab {
    TabActivities -> SourceActivities
    TabBeachBus -> SourceBeachBus
    TabClimbingWall -> SourceClimbingWall
    TabFavourites -> SourceFavourites
  }
}

/// The fetch-state `RemoteData` backing a source (the per-tab id window, or the
/// favourited fetch). Used to decide lazy loading and render the tab's state.
pub fn source_remote(
  model: Model,
  source: ActivityListSource,
) -> RemoteData(List(Uuid)) {
  case source {
    SourceActivities -> model.activities_ids
    SourceBeachBus -> model.beach_bus_ids
    SourceClimbingWall -> model.climbing_wall_ids
    SourceFavourites -> model.favourited
  }
}

pub fn set_source_remote(
  model: Model,
  source: ActivityListSource,
  remote: RemoteData(List(Uuid)),
) -> Model {
  case source {
    SourceActivities -> Model(..model, activities_ids: remote)
    SourceBeachBus -> Model(..model, beach_bus_ids: remote)
    SourceClimbingWall -> Model(..model, climbing_wall_ids: remote)
    SourceFavourites -> Model(..model, favourited: remote)
  }
}

/// Lazily load a source: if never fetched, mark it `Loading` and fire the
/// fetch; otherwise leave the cache untouched (instant tab switch).
pub fn ensure_source_loaded(
  model: Model,
  source: ActivityListSource,
) -> #(Model, Effect(Msg)) {
  case source_remote(model, source) {
    NotAsked -> #(set_source_remote(model, source, Loading), fetch_list(source))
    Loading | Loaded(_) | Failed(_) -> #(model, effect.none())
  }
}

/// Resolves a tab into the `RemoteData` of summaries to render. Browse tabs map
/// their id window through the entity cache (dropping ids not yet cached).
/// Favourites derives membership from the complete `statuses` map; its
/// `favourited` fetch only supplies hydration + loading/error state.
pub fn tab_summaries(
  model: Model,
  tab: ActivitiesFilterTab,
) -> RemoteData(List(ActivitySummary)) {
  case tab {
    TabFavourites -> {
      // Membership is derived from the complete `statuses` map; the `favourited`
      // fetch only supplies hydration (summaries for fav/booked items not yet in
      // the cache, e.g. beach-bus/climbing-wall slots) + the first-load state.
      let derived =
        model.statuses
        |> dict.keys
        |> list.filter(fn(id) { is_favourited(status_of(model.statuses, id)) })
        |> list.filter_map(fn(id) { dict.get(model.activities, id) })
      case derived, model.favourited {
        // Nothing cached to render yet — reflect the fetch state.
        [], NotAsked -> NotAsked
        [], Loading -> Loading
        [], Failed(err) -> Failed(err)
        // We can already render from the cache. Show it and let any refetch
        // hydrate in the background instead of blanking the list with a blocking
        // spinner — which, on slow networks, reads as a failed load when
        // re-entering Favourites after a favourite/booking change.
        _, _ -> Loaded(derived)
      }
    }
    _ ->
      case source_remote(model, tab_source(tab)) {
        NotAsked -> NotAsked
        Loading -> Loading
        Failed(err) -> Failed(err)
        Loaded(ids) ->
          Loaded(
            list.filter_map(ids, fn(id) { dict.get(model.activities, id) }),
          )
      }
  }
}

/// Merge a list response into the entity cache (overwrite on overlap).
pub fn hydrate(
  store: Dict(Uuid, ActivitySummary),
  items: List(ActivitySummary),
) -> Dict(Uuid, ActivitySummary) {
  list.fold(items, store, fn(acc, s) { dict.insert(acc, s.id, s) })
}

/// The cached full activity for a detail view, composed from the slim summary
/// (`activities`) and the lazily-loaded detail-only fields (`details`). Defaults
/// to `Loading` while a fetch is expected but the cache has no entry yet.
fn detail_of(model: Model, id: Uuid) -> RemoteData(Activity) {
  case dict.get(model.details, id) {
    Error(_) | Ok(NotAsked) | Ok(Loading) -> Loading
    Ok(Failed(err)) -> Failed(err)
    Ok(Loaded(detail)) ->
      case dict.get(model.activities, id) {
        Ok(summary) -> Loaded(to_activity(summary, detail))
        // A loaded detail always arrives with its summary (see
        // `ApiReturnedActivity`), so this is unreachable in practice.
        Error(_) -> Loading
      }
  }
}

/// Marks a detail page's activity as `Loading` in the cache when a fetch is
/// about to start, so the detail view shows a spinner instead of a flash of
/// "not found".
fn seed_detail_loading(
  details: Dict(Uuid, RemoteData(ActivityDetail)),
  page: Page,
) -> Dict(Uuid, RemoteData(ActivityDetail)) {
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
    location_name: option.map(a.location, fn(l) { l.name }),
    tags: a.tags,
    target_groups: a.target_groups,
  )
}

/// Extract the detail-only fields from a full activity.
fn to_detail(a: Activity) -> ActivityDetail {
  ActivityDetail(
    description: a.description,
    location: a.location,
    tags: a.tags,
    target_groups: a.target_groups,
  )
}

/// Compose a full activity from a cached summary and its loaded detail fields.
fn to_activity(summary: ActivitySummary, detail: ActivityDetail) -> Activity {
  model.Activity(
    id: summary.id,
    title: summary.title,
    description: detail.description,
    max_attendees: summary.max_attendees,
    start_time: summary.start_time,
    end_time: summary.end_time,
    location: detail.location,
    tags: detail.tags,
    target_groups: detail.target_groups,
  )
}

fn map_loaded(
  remote: RemoteData(List(a)),
  f: fn(List(a)) -> List(a),
) -> RemoteData(List(a)) {
  case remote {
    Loaded(items) -> Loaded(f(items))
    NotAsked | Loading | Failed(_) -> remote
  }
}

/// Prepend an id to a loaded id window (no-op while not loaded; dedups).
pub fn prepend_id(
  remote: RemoteData(List(Uuid)),
  id: Uuid,
) -> RemoteData(List(Uuid)) {
  use ids <- map_loaded(remote)
  case list.contains(ids, id) {
    True -> ids
    False -> [id, ..ids]
  }
}

/// Drop an id from a loaded id window (no-op while not loaded).
pub fn remove_id(
  remote: RemoteData(List(Uuid)),
  id: Uuid,
) -> RemoteData(List(Uuid)) {
  use ids <- map_loaded(remote)
  list.filter(ids, fn(x) { x != id })
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
    use title_en <- form.field(
      "title_en",
      form.parse_string |> form.check_not_empty,
    )
    use description <- form.field("description", form.parse_string)
    use description_en <- form.field("description_en", form.parse_string)
    use max_attendees <- form.field(
      "max_attendees",
      form.parse_optional(form.parse_int),
    )
    use start_time <- form.field("start_time", form.parse_date_time)
    use end_time <- form.field("end_time", form.parse_date_time)
    form.success(ActivityForm(
      title:,
      title_en:,
      description:,
      description_en:,
      max_attendees:,
      start_time:,
      end_time:,
    ))
  })
}

fn form_from_activity(activity: Activity) -> Form(ActivityForm) {
  activity_form()
  |> form.add_string("title", activity.title.sv)
  |> form.add_string("title_en", activity.title.en)
  |> form.add_string("description", activity.description.sv)
  |> form.add_string("description_en", activity.description.en)
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

pub fn translator_for(lang: String) -> Translator {
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

/// The active language code (e.g. `"sv"` or `"en"`) for the translator, using
/// the same locale lookup `translator_for` relies on.
fn current_language(translator: Translator) -> String {
  translator |> g18n.locale |> locale.language
}

/// Pick the Swedish or English variant of a bilingual value by active language.
/// Used for database-sourced text (e.g. location names), which g18n's
/// translation keys don't cover.
fn localized(translator: Translator, value: model.BilingualString) -> String {
  case current_language(translator) {
    "en" -> value.en
    _ -> value.sv
  }
}

fn app_bar_title(translator: Translator, page: Page) -> Option(String) {
  case page {
    ActivitiesListPage(_) ->
      Some(g18n.translate(translator, "app_bar.activities_list"))
    ActivityDetailPage(_, _) ->
      Some(g18n.translate(translator, "app_bar.activity_detail"))
    ActivityNewPage(..) ->
      Some(g18n.translate(translator, "app_bar.activity_new"))
    ActivityEditPage(_, _) -> None
    NotFoundPage -> None
  }
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let translator = translator_for(get_html_lang())

  let #(page, page_effect) = case modem.initial_uri() {
    Ok(uri) -> uri_to_page(uri, dict.new())
    Error(_) -> #(ActivitiesListPage(default_filters()), effect.none())
  }

  let model =
    Model(
      page:,
      translator:,
      activities: dict.new(),
      // Default tab loads immediately; other sources load lazily on first open.
      activities_ids: Loading,
      beach_bus_ids: NotAsked,
      climbing_wall_ids: NotAsked,
      favourited: NotAsked,
      details: seed_detail_loading(dict.new(), page),
      statuses: dict.new(),
      spots: dict.new(),
      activity_tags: dict.new(),
      roles: initial_roles(),
    )

  let title_effect = case app_bar_title(translator, page) {
    Some(title) -> set_app_bar_title(title)
    None -> effect.none()
  }

  #(
    model,
    effect.batch([
      modem.init(OnRouteChange),
      observe_lang(),
      fetch_list(SourceActivities),
      fetch_spots(),
      fetch_activity_tags(),
      page_effect,
      // Always attempt; a 401 (anonymous user) leaves the status dict empty.
      fetch_statuses(),
      title_effect,
    ]),
  )
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  // Routing
  OnRouteChange(Uri)
  // Locale
  LangChanged(String)
  // API responses
  ApiReturnedActivityList(
    ActivityListSource,
    Result(List(ActivitySummary), rsvp.Error),
  )
  ApiReturnedActivity(Uuid, Result(Activity, rsvp.Error))
  ApiReturnedStatuses(Result(List(ActivityStatusEntry), rsvp.Error))
  ApiReturnedActivitySpots(Result(List(ActivitySpots), rsvp.Error))
  ApiReturnedActivitySpotsOne(Uuid, Result(Int, rsvp.Error))
  ApiReturnedActivityTags(Result(List(ActivityTag), rsvp.Error))
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
  UserClickedShowBookings
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
  UserToggledTargetGroup(TargetGroup)
  UserToggledTag(Uuid)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
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

    ApiReturnedActivityList(source, Ok(items)) -> {
      let activities = hydrate(model.activities, items)
      let ids = list.map(items, fn(s) { s.id })
      #(
        set_source_remote(Model(..model, activities:), source, Loaded(ids)),
        effect.none(),
      )
    }

    ApiReturnedActivityList(source, Error(_)) -> #(
      set_source_remote(model, source, Failed(LoadActivitiesFailed)),
      effect.none(),
    )

    ApiReturnedActivity(id, Ok(activity)) -> #(
      // A detail fetch carries the whole activity, so refresh the summary too —
      // this both keeps the two caches in sync and populates the summary on
      // direct navigation to an activity we never listed.
      Model(
        ..model,
        activities: dict.insert(model.activities, id, to_summary(activity)),
        details: dict.insert(model.details, id, Loaded(to_detail(activity))),
      ),
      effect.none(),
    )

    ApiReturnedActivity(id, Error(_)) -> #(
      Model(
        ..model,
        details: dict.insert(model.details, id, Failed(LoadActivityFailed)),
      ),
      effect.none(),
    )

    ApiReturnedStatuses(Ok(entries)) -> {
      let statuses =
        list.fold(entries, dict.new(), fn(acc, entry) {
          dict.insert(acc, entry.activity_id, entry.status)
        })
      #(Model(..model, statuses:), effect.none())
    }

    // Keep the prior status dict on failure.
    ApiReturnedStatuses(Error(_)) -> #(model, effect.none())

    ApiReturnedActivitySpots(Ok(entries)) -> {
      let spots =
        list.fold(entries, dict.new(), fn(acc, entry) {
          dict.insert(acc, entry.activity_id, entry.spots_booked)
        })
      #(Model(..model, spots:), effect.none())
    }

    // Keep the prior counts on failure (missing keys still read as unknown).
    ApiReturnedActivitySpots(Error(_)) -> #(model, effect.none())

    ApiReturnedActivitySpotsOne(id, Ok(spots_booked)) -> #(
      Model(..model, spots: dict.insert(model.spots, id, spots_booked)),
      effect.none(),
    )

    ApiReturnedActivitySpotsOne(_, Error(_)) -> #(model, effect.none())

    ApiReturnedActivityTags(Ok(tags)) -> {
      let activity_tags =
        list.fold(tags, dict.new(), fn(acc, tag) {
          dict.insert(acc, tag.id, tag)
        })
      #(Model(..model, activity_tags:), effect.none())
    }

    // Keep the prior vocabulary (empty) on failure; tag chips just won't show.
    ApiReturnedActivityTags(Error(_)) -> #(model, effect.none())

    ApiCreatedActivity(Ok(activity)) -> #(
      Model(
        ..model,
        activities: dict.insert(
          model.activities,
          activity.id,
          to_summary(activity),
        ),
        // Show it immediately in the all-activities window. The kind is
        // server-internal, so we can't tell if it belongs to a special tab —
        // invalidate those windows so they refetch on next open.
        activities_ids: prepend_id(model.activities_ids, activity.id),
        beach_bus_ids: NotAsked,
        climbing_wall_ids: NotAsked,
        details: dict.insert(
          model.details,
          activity.id,
          Loaded(to_detail(activity)),
        ),
      ),
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiCreatedActivity(Error(_)) ->
      case model.page {
        ActivityNewPage(form, _, tags, target_groups) -> #(
          Model(
            ..model,
            page: ActivityNewPage(
              form,
              Some(CreateActivityFailed),
              tags,
              target_groups,
            ),
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
            EditReady(
              activity,
              form_from_activity(activity),
              None,
              activity.tags,
              activity.target_groups,
            ),
          )
        other -> other
      }
      #(
        Model(
          ..model,
          activities: dict.insert(
            model.activities,
            activity.id,
            to_summary(activity),
          ),
          details: dict.insert(
            model.details,
            activity.id,
            Loaded(to_detail(activity)),
          ),
          page:,
        ),
        effect.none(),
      )
    }

    ApiUpdatedActivity(Error(_)) ->
      case model.page {
        ActivityEditPage(id, edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(..edit, submit_error: Some(UpdateActivityFailed)),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    ApiDeletedActivity(id, Ok(_)) -> #(
      Model(
        ..model,
        activities: dict.delete(model.activities, id),
        activities_ids: remove_id(model.activities_ids, id),
        beach_bus_ids: remove_id(model.beach_bus_ids, id),
        climbing_wall_ids: remove_id(model.climbing_wall_ids, id),
        favourited: remove_id(model.favourited, id),
        details: dict.delete(model.details, id),
        statuses: dict.delete(model.statuses, id),
      ),
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiDeletedActivity(_, Error(_)) ->
      case model.page {
        ActivityEditPage(id, edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(..edit, submit_error: Some(DeleteActivityFailed)),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedCreateForm(Ok(activity_form)) ->
      case model.page {
        ActivityNewPage(_, _, tags, target_groups) -> #(
          model,
          create_activity(activity_form, tags, target_groups),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedCreateForm(Error(f)) ->
      case model.page {
        ActivityNewPage(_, submit_error, tags, target_groups) -> #(
          Model(
            ..model,
            page: ActivityNewPage(f, submit_error, tags, target_groups),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedEditForm(Ok(activity_form)) ->
      case model.page {
        ActivityEditPage(id, edit) -> #(
          model,
          update_activity(id, activity_form, edit.tags, edit.target_groups),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedEditForm(Error(f)) ->
      case model.page {
        ActivityEditPage(id, edit) -> #(
          Model(..model, page: ActivityEditPage(id, EditReady(..edit, form: f))),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserClickedEdit -> #(model, effect.none())

    // The "Visa bokningar" button on the detail page: view this activity's
    // bookings. Not yet implemented — wiring is a later task.
    UserClickedShowBookings -> #(model, effect.none())

    UserClickedCancelEdit ->
      case model.page {
        ActivityEditPage(id, edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(
                ..edit,
                form: form_from_activity(edit.activity),
                submit_error: None,
                tags: edit.activity.tags,
                target_groups: edit.activity.target_groups,
              ),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserClickedDelete ->
      case model.page {
        ActivityEditPage(id, EditReady(..)) -> #(model, delete_activity(id))
        _ -> #(model, effect.none())
      }

    UserSearchedActivities(value) ->
      update_filters(model, fn(f) { ListFilters(..f, search: value) })

    UserSelectedTab(index) ->
      case model.page {
        ActivitiesListPage(filters) -> {
          let tab = tab_from_index(index)
          let #(model, fetch_effect) =
            ensure_source_loaded(model, tab_source(tab))
          #(
            Model(
              ..model,
              page: ActivitiesListPage(ListFilters(..filters, tab:)),
            ),
            fetch_effect,
          )
        }
        _ -> #(model, effect.none())
      }

    UserSelectedDay(d) ->
      update_filters(model, fn(f) { ListFilters(..f, day: d) })

    UserToggledMoreFilters ->
      update_filters(model, fn(f) { ListFilters(..f, more_open: !f.more_open) })

    // Target-group / tag chips are reused by both the list filter panel and the
    // create/edit form, so the same message toggles either the active filters or
    // the page's working selection, depending on the current page.
    UserToggledTargetGroup(target_group) ->
      case model.page {
        ActivityNewPage(form, submit_error, tags, target_groups) -> #(
          Model(
            ..model,
            page: ActivityNewPage(
              form,
              submit_error,
              tags,
              toggle_member(target_groups, target_group),
            ),
          ),
          effect.none(),
        )
        ActivityEditPage(id, edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(
                ..edit,
                target_groups: toggle_member(edit.target_groups, target_group),
              ),
            ),
          ),
          effect.none(),
        )
        _ ->
          update_filters(model, fn(f) {
            ListFilters(
              ..f,
              target_groups: toggle_member(f.target_groups, target_group),
            )
          })
      }

    UserToggledTag(tag_id) ->
      case model.page {
        ActivityNewPage(form, submit_error, tags, target_groups) -> #(
          Model(
            ..model,
            page: ActivityNewPage(
              form,
              submit_error,
              toggle_member(tags, tag_id),
              target_groups,
            ),
          ),
          effect.none(),
        )
        ActivityEditPage(id, edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              EditReady(..edit, tags: toggle_member(edit.tags, tag_id)),
            ),
          ),
          effect.none(),
        )
        _ ->
          update_filters(model, fn(f) {
            ListFilters(..f, tags: toggle_member(f.tags, tag_id))
          })
      }

    UserClickedRetryLoad -> {
      let tab = case model.page {
        ActivitiesListPage(filters) -> filters.tab
        _ -> TabActivities
      }
      let source = tab_source(tab)
      #(set_source_remote(model, source, Loading), fetch_list(source))
    }

    UserToggledFavourite(activity_id) ->
      case status_of(model.statuses, activity_id) {
        // Booked => heart is locked; can't unfavourite.
        Booked(_) -> #(model, effect.none())
        Favourited -> #(
          Model(..model, statuses: dict.delete(model.statuses, activity_id)),
          remove_favourite(activity_id),
        )
        // Optimistic; a 401 for an anonymous user reverts via ApiToggledFavourite.
        // Invalidate the favourited window so the next Favourites open refetches
        // and hydrates this newly-relevant summary.
        NotInterested -> #(
          Model(
            ..model,
            statuses: dict.insert(model.statuses, activity_id, Favourited),
            favourited: NotAsked,
          ),
          add_favourite(activity_id),
        )
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
      // Booking auto-favourites server-side, so invalidate the favourited
      // window to pick up this newly-relevant summary on next Favourites open.
      #(
        Model(..model, statuses:, page:, favourited: NotAsked),
        fetch_activity_spots(booking.activity_id),
      )
    }

    ApiCreatedBooking(Error(_)) ->
      case model.page {
        ActivityDetailPage(id, BookingSubmitting(mode)) -> #(
          Model(
            ..model,
            page: ActivityDetailPage(
              id,
              BookingOpen(new_booking_form(), Some(CreateBookingFailed), mode),
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
      #(
        Model(..model, statuses:, page:),
        fetch_activity_spots(booking.activity_id),
      )
    }

    ApiUpdatedBooking(Error(_)) ->
      case model.page {
        ActivityDetailPage(id, BookingSubmitting(mode)) -> #(
          Model(
            ..model,
            page: ActivityDetailPage(
              id,
              BookingOpen(new_booking_form(), Some(UpdateBookingFailed), mode),
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
      #(Model(..model, statuses:, page:), fetch_activity_spots(activity_id))
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

pub fn toggle_member(items: List(a), name: a) -> List(a) {
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

fn list_source_path(source: ActivityListSource) -> String {
  case source {
    SourceActivities -> "/api/activities"
    SourceBeachBus -> "/api/beach-bus-activities"
    SourceClimbingWall -> "/api/climbing-wall-activities"
    SourceFavourites -> "/api/favourited-activities"
  }
}

fn fetch_list(source: ActivityListSource) -> Effect(Msg) {
  rsvp.get(
    api_prefix <> list_source_path(source),
    rsvp.expect_json(model.activity_summaries_decoder(), fn(result) {
      ApiReturnedActivityList(source, result)
    }),
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

/// Fetch booked-spot counts for every activity (replaces the whole `spots`
/// cache). Idempotent — safe to re-fire on an interval if polling is added.
fn fetch_spots() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activity-spots",
    rsvp.expect_json(
      model.activity_spots_list_decoder(),
      ApiReturnedActivitySpots,
    ),
  )
}

/// Fetch the live booked-spot count for a single activity. Used on detail open
/// and after booking mutations, so the count reflects concurrent bookings by
/// other users too.
fn fetch_activity_spots(id: Uuid) -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activities/" <> uuid.to_string(id) <> "/spots",
    rsvp.expect_json(model.spots_booked_decoder(), fn(result) {
      ApiReturnedActivitySpotsOne(id, result)
    }),
  )
}

fn add_favourite(activity_id: Uuid) -> Effect(Msg) {
  rsvp.put(
    api_prefix
      <> "/api/activities/"
      <> uuid.to_string(activity_id)
      <> "/favourite",
    json.null(),
    rsvp.expect_ok_response(fn(result) {
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
    rsvp.expect_ok_response(fn(result) {
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
    rsvp.expect_ok_response(fn(result) {
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

fn create_activity(
  af: ActivityForm,
  tags: List(Uuid),
  target_groups: List(TargetGroup),
) -> Effect(Msg) {
  rsvp.post(
    api_prefix <> "/api/activities",
    activity_form_to_json(af, tags, target_groups),
    rsvp.expect_json(model.activity_decoder(), ApiCreatedActivity),
  )
}

fn update_activity(
  id: Uuid,
  af: ActivityForm,
  tags: List(Uuid),
  target_groups: List(TargetGroup),
) -> Effect(Msg) {
  rsvp.put(
    api_prefix <> "/api/activities/" <> uuid.to_string(id),
    activity_form_to_json(af, tags, target_groups),
    rsvp.expect_json(model.activity_decoder(), ApiUpdatedActivity),
  )
}

fn fetch_activity_tags() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activity-tags",
    rsvp.expect_json(model.activity_tags_decoder(), ApiReturnedActivityTags),
  )
}

fn delete_activity(id: Uuid) -> Effect(Msg) {
  rsvp.delete(
    api_prefix <> "/api/activities/" <> uuid.to_string(id),
    json.null(),
    rsvp.expect_ok_response(fn(result) {
      case result {
        Ok(_) -> ApiDeletedActivity(id, Ok(Nil))
        Error(err) -> ApiDeletedActivity(id, Error(err))
      }
    }),
  )
}

fn activity_form_to_json(
  af: ActivityForm,
  tags: List(Uuid),
  target_groups: List(TargetGroup),
) -> json.Json {
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
    #(
      "title",
      model.bilingual_string_to_json(model.BilingualString(
        sv: af.title,
        en: af.title_en,
      )),
    ),
    #(
      "description",
      model.bilingual_string_to_json(model.BilingualString(
        sv: af.description,
        en: af.description_en,
      )),
    ),
    #("max_attendees", case af.max_attendees {
      Some(n) -> json.int(n)
      None -> json.null()
    }),
    #("start_time", json.int(to_secs(af.start_time))),
    #("end_time", json.int(to_secs(af.end_time))),
    #("tags", json.array(tags, fn(id) { json.string(uuid.to_string(id)) })),
    #("target_groups", json.array(target_groups, model.target_group_to_json)),
  ])
}

// ROUTING ---------------------------------------------------------------------

pub fn uri_to_page(
  uri: Uri,
  details: Dict(Uuid, RemoteData(ActivityDetail)),
) -> #(Page, Effect(Msg)) {
  case uri.path_segments(uri.path) |> list.drop(2) {
    ["activities"] | [] -> #(
      ActivitiesListPage(default_filters()),
      effect.none(),
    )
    ["activities", "new"] -> #(
      ActivityNewPage(activity_form(), None, [], []),
      effect.none(),
    )
    ["activities", id_str] ->
      case uuid.from_string(id_str) {
        Ok(id) -> {
          // Reuse the cached activity if present; otherwise fetch it lazily.
          let activity_effect = case dict.get(details, id) {
            Ok(Loaded(_)) -> effect.none()
            _ -> fetch_activity(id)
          }
          // Always refetch the spot count on open — it's cheap, volatile, and
          // this is the screen where the user is about to book.
          #(
            ActivityDetailPage(id, BookingClosed),
            effect.batch([activity_effect, fetch_activity_spots(id)]),
          )
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
        tab_summaries(model, filters.tab),
        model.statuses,
        model.spots,
        filters,
        model.activity_tags,
      )
    ActivityNewPage(form, submit_error, tags, target_groups) ->
      view_activity_new(
        model.translator,
        form,
        submit_error,
        tags,
        target_groups,
        model.activity_tags,
      )
    ActivityDetailPage(id, booking) ->
      view_activity_detail(
        model.translator,
        detail_of(model, id),
        status_of(model.statuses, id),
        dict.get(model.spots, id) |> option.from_result,
        booking,
        model.activity_tags,
        can_manage_activities(model),
      )
    ActivityEditPage(_, _) -> view_not_found()
    NotFoundPage -> view_not_found()
  }
}

fn view_activities_list(
  translator: Translator,
  summaries: RemoteData(List(ActivitySummary)),
  statuses: Dict(Uuid, ActivityStatus),
  spots: Dict(Uuid, Int),
  filters: ListFilters,
  activity_tags: Dict(Uuid, ActivityTag),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }

  html.div([attribute.class("flex flex-col")], [
    view_list_top_bar(translator, filters, summaries),
    case filters.more_open {
      True -> view_more_filters_panel(translator, filters, activity_tags)
      False -> element.none()
    },
    html.div([attribute.class("flex flex-col gap-3 mt-3")], [
      case summaries {
        NotAsked | Loading -> component.scout_loader(t("activity.loading"))
        Failed(err) ->
          html.div([attribute.class("py-6 flex flex-col items-center gap-3")], [
            component.error_banner(t("error.heading"), t(app_error_key(err))),
            component.scout_button_action(
              t("list.retry"),
              "primary",
              UserClickedRetryLoad,
            ),
          ])
        Loaded([]) ->
          html.div([attribute.class("py-6 text-center flex flex-col gap-3")], [
            html.p([], [element.text("No activities yet.")]),
          ])
        Loaded(items) ->
          view_grouped_activities(
            translator,
            to_card_items(items, statuses, spots),
            filters,
          )
      },
    ]),
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
        "flex flex-col gap-2 bg-white border-b border-gray-200 p-3",
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
      // Key the day select by its date set: `scout-select` consumes its own
      // `<option>` children, so reconciling them in place desyncs Lustre's DOM
      // when the list changes (e.g. switching tabs). A content-derived key makes
      // Lustre replace the whole element instead.
      keyed.div([attribute.class("flex items-center gap-2")], [
        #(
          "day-select-" <> string.join(list.map(dates, date_to_iso), ","),
          view_day_select(translator, filters.day, dates),
        ),
        #(
          "more-filters",
          component.filter_pill_icon(
            t("list.filter.more"),
            icons.filter,
            filters.more_open,
            UserToggledMoreFilters,
          ),
        ),
      ]),
    ],
  )
}

fn tab_label(translator: Translator, tab: ActivitiesFilterTab) -> String {
  case tab {
    TabActivities -> g18n.translate(translator, "list.tab.activities")
    TabBeachBus -> g18n.translate(translator, "list.tab.beach_bus")
    TabClimbingWall -> g18n.translate(translator, "list.tab.climbing_wall")
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
  activity_tags: Dict(Uuid, ActivityTag),
) -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "bg-white border-b border-gray-200 p-3 flex flex-col gap-3",
      ),
    ],
    view_target_group_and_tag_pickers(
      translator,
      filters.target_groups,
      filters.tags,
      activity_tags,
    ),
  )
}

/// The målgrupp + tags chip groups, shared by the list filter panel and the
/// create/edit form. Selection state and the toggle messages are the same in
/// both places — `UserToggledTargetGroup`/`UserToggledTag` act on whichever page
/// is active.
fn view_target_group_and_tag_pickers(
  translator: Translator,
  selected_target_groups: List(TargetGroup),
  selected_tags: List(Uuid),
  activity_tags: Dict(Uuid, ActivityTag),
) -> List(Element(Msg)) {
  let t = fn(key) { g18n.translate(translator, key) }
  let tags =
    dict.values(activity_tags)
    |> list.sort(fn(a, b) {
      string.compare(
        localized(translator, a.name),
        localized(translator, b.name),
      )
    })
  [
    html.div([attribute.class("flex flex-col gap-2")], [
      html.h4([attribute.class("text-body-sm font-semibold")], [
        element.text(t("list.filter.audience_label")),
      ]),
      html.div(
        [attribute.class("flex flex-wrap gap-2")],
        list.map(model.target_groups_all(), fn(target_group) {
          component.filter_chip(
            target_group_label(target_group),
            list.contains(selected_target_groups, target_group),
            UserToggledTargetGroup(target_group),
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
        list.map(tags, fn(tag) {
          component.filter_chip(
            localized(translator, tag.name),
            list.contains(selected_tags, tag.id),
            UserToggledTag(tag.id),
          )
        }),
      ),
    ]),
  ]
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
        [attribute.class("flex flex-col gap-4 px-3 pb-4")],
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
  let spots_text =
    spots_remaining_text(translator, summary.max_attendees, item.spots_booked)
  let status = card_status(translator, summary, item.status)
  component.activity_card(
    api_prefix <> "/activities/" <> id,
    localized(translator, summary.title),
    status,
    is_favourited(item.status),
    UserToggledFavourite(summary.id),
    time,
    option.map(summary.location_name, fn(n) { localized(translator, n) }),
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
  translator: g18n.Translator,
  form: Form(ActivityForm),
  submit_error: Option(AppError),
  selected_tags: List(Uuid),
  selected_target_groups: List(TargetGroup),
  activity_tags: Dict(Uuid, ActivityTag),
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
        Some(err) ->
          component.error_banner(
            g18n.translate(translator, "error.heading"),
            g18n.translate(translator, app_error_key(err)),
          )
        None -> element.none()
      },
      html.form([event.on_submit(submitted)], [
        component.scout_card([
          html.div([attribute.class("flex flex-col gap-2")], [
            component.scout_form_field(form, "Title (Swedish)", "text", "title"),
            component.scout_form_field(
              form,
              "Title (English)",
              "text",
              "title_en",
            ),
            component.scout_form_field(
              form,
              "Description (Swedish)",
              "text",
              "description",
            ),
            component.scout_form_field(
              form,
              "Description (English)",
              "text",
              "description_en",
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
            ..list.append(
              view_target_group_and_tag_pickers(
                translator,
                selected_target_groups,
                selected_tags,
                activity_tags,
              ),
              [
                element.element(
                  "scout-button",
                  [
                    attribute.attribute("variant", "primary"),
                    attribute.attribute("type", "submit"),
                  ],
                  [element.text("Create")],
                ),
              ],
            )
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
  spots_booked: Option(Int),
  booking: BookingFormState,
  activity_tags: Dict(Uuid, ActivityTag),
  can_manage: Bool,
) -> Element(Msg) {
  case state {
    NotAsked | Loading ->
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
      view_activity_detail_loaded(
        translator,
        activity,
        status,
        spots_booked,
        booking,
        activity_tags,
        can_manage,
      )
  }
}

/// Builds the map preview iframe URL for a location. The map's `icon` param
/// takes the bare tabler icon name, without the `tabler-` prefix locations
/// store it with.
fn map_preview_src(location: model.Location) -> String {
  let icon = string.replace(location.icon_name, each: "tabler-", with: "")
  "/_services/map/preview.html?lat="
  <> float.to_string(location.latitude)
  <> "&lng="
  <> float.to_string(location.longitude)
  <> "&icon="
  <> icon
  <> "&variant="
  <> location.icon_variant
}

fn view_activity_detail_loaded(
  translator: Translator,
  activity: Activity,
  status: ActivityStatus,
  spots_booked: Option(Int),
  booking: BookingFormState,
  activity_tags: Dict(Uuid, ActivityTag),
  can_manage: Bool,
) -> Element(Msg) {
  let heart_btn =
    component.heart_button(
      is_favourited(status),
      is_booked(status),
      UserToggledFavourite(activity.id),
      False,
    )
  html.div([attribute.class("flex flex-col")], [
    component.scout_drawer(
      case booking {
        BookingOpen(_, _, _) | BookingSubmitting(_) -> True
        BookingClosed | UnbookConfirming(_) | UnbookSubmitting(_) -> False
      },
      booking_drawer_heading(translator, booking),
      UserClickedCancelBooking,
      [view_booking_form_section(translator, booking)],
    ),
    case activity.location {
      Some(location) ->
        html.div(
          // Map
          [
            attribute.class("sticky top-0 h-28"),
          ],
          [
            html.iframe([
              attribute.src(map_preview_src(location)),
              attribute.class("w-full h-full outline-none pointer-events-none"),
              attribute.loading("lazy"),
            ]),
          ],
        )
      None -> element.none()
    },
    html.div(
      // Content
      [
        attribute.class(
          "z-10 bg-white border-t border-gray-200 flex-1 flex flex-col p-3 gap-4",
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
                [element.text(localized(translator, activity.title))],
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
              // Management-only: view this activity's bookings. Shown only to
              // users who can manage activities, and only for bookable
              // activities (others can't have bookings).
              case can_manage && option.is_some(activity.max_attendees) {
                True ->
                  component.scout_button_action(
                    g18n.translate(translator, "activity.show_bookings"),
                    "outlined",
                    UserClickedShowBookings,
                  )
                False -> element.none()
              },
              case
                spots_remaining_text(
                  translator,
                  activity.max_attendees,
                  spots_booked,
                )
              {
                Some(text) ->
                  html.div(
                    [
                      attribute.class(
                        "flex gap-2 items-center text-body-sm text-gray-500",
                      ),
                    ],
                    [
                      component.icon(icons.users, "size-4"),
                      html.p([attribute.class("flex-1")], [element.text(text)]),
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
            case activity.location {
              Some(location) ->
                component.quick_info_tile(
                  icons.pin,
                  g18n.translate(translator, "activity.location"),
                  [element.text(localized(translator, location.name))],
                )
              None -> element.none()
            },
          ],
        ),
        html.div([], [
          html.p([attribute.class("text-body-m")], [
            element.text(localized(translator, activity.description)),
          ]),
        ]),
        view_detail_chips(translator, activity, activity_tags),
      ],
    ),
  ])
}

/// The activity's målgrupp and tags rendered as read-only badges. Renders
/// nothing when the activity has neither. Tag ids are resolved to labels via the
/// fetched vocabulary; ids not yet resolved are skipped.
fn view_detail_chips(
  translator: Translator,
  activity: Activity,
  activity_tags: Dict(Uuid, ActivityTag),
) -> Element(Msg) {
  let target_group_badges =
    activity.target_groups
    |> list.map(fn(target_group) {
      component.badge(component.BadgePurple, target_group_label(target_group))
    })
  let tag_badges =
    activity.tags
    |> list.filter_map(fn(id) {
      case dict.get(activity_tags, id) {
        Ok(tag) ->
          Ok(component.badge(
            component.BadgeGreen,
            localized(translator, tag.name),
          ))
        Error(_) -> Error(Nil)
      }
    })
  case list.append(target_group_badges, tag_badges) {
    [] -> element.none()
    badges -> html.div([attribute.class("flex flex-wrap gap-2")], badges)
  }
}

/// Heading for the booking drawer, based on whether the user is creating a
/// new booking or changing an existing one. Empty when the drawer is closed.
fn booking_drawer_heading(
  translator: Translator,
  booking: BookingFormState,
) -> String {
  case booking {
    BookingOpen(_, _, BookingNew) | BookingSubmitting(BookingNew) ->
      g18n.translate(translator, "activity.book")
    BookingOpen(_, _, BookingEdit(_)) | BookingSubmitting(BookingEdit(_)) ->
      g18n.translate(translator, "booking.change")
    BookingClosed | UnbookConfirming(_) | UnbookSubmitting(_) -> ""
  }
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

    // Booked: offer "Ändra bokning" + "Avboka" — kept visible even while the
    // booking drawer is open/submitting, since the drawer no longer hides
    // the row behind it.
    True, _ -> #(
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
        html.div([attribute.class("flex flex-col gap-2")], [
          case submit_error {
            Some(err) ->
              component.error_banner(
                g18n.translate(translator, "error.heading"),
                g18n.translate(translator, app_error_key(err)),
              )
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
      ])
    }
  }
}

pub type IntervalClasses {
  SameDayDifferentTime
  SameDaySameTime
  DifferentDays
}

pub fn classify_interval(
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

/// The Swedish scout section label for a target group (målgrupp). Section names
/// are proper nouns, so the same label is shown regardless of active language.
fn target_group_label(target_group: TargetGroup) -> String {
  case target_group {
    model.Sparare -> "Spårare"
    model.Upptackare -> "Upptäckare"
    model.Aventyrare -> "Äventyrare"
    model.Utmanare -> "Utmanare"
    model.Rover -> "Rover"
  }
}

/// The "spots remaining" label to show, or `None` for an uncapped activity
/// (which shows no text). A capped activity with an unknown count shows an
/// explicit "unknown" label rather than a number.
fn spots_remaining_text(
  translator: Translator,
  max_attendees: Option(Int),
  spots_booked: Option(Int),
) -> Option(String) {
  case model.spots_remaining(max_attendees, spots_booked) {
    model.Unlimited -> None
    model.Remaining(remaining) ->
      Some(g18n.translate_plural(
        translator,
        "activity.spots_remaining",
        remaining,
      ))
    model.UnknownSpots ->
      Some(g18n.translate(translator, "activity.spots_unknown"))
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

fn lists_intersect(a: List(a), b: List(a)) -> Bool {
  list.any(a, fn(x) { list.contains(b, x) })
}

pub fn apply_filters(items: List(CardItem), f: ListFilters) -> List(CardItem) {
  let needle = string.lowercase(string.trim(f.search))
  use item <- list.filter(items)
  let summary = item.summary
  let title_match = case needle {
    "" -> True
    _ ->
      string.contains(string.lowercase(summary.title.sv), needle)
      || string.contains(string.lowercase(summary.title.en), needle)
  }
  let day_match = case f.day {
    None -> True
    Some(date) -> date_of(summary.start_time) == date
  }
  // Membership (tab/favourites) is resolved upstream via the source id windows
  // and the statuses-derived favourites set, so every tab is pass-through on
  // status here; only search + day + target group + tags filter client-side.
  let target_group_match = case f.target_groups {
    [] -> True
    selected -> lists_intersect(summary.target_groups, selected)
  }
  let tag_match = case f.tags {
    [] -> True
    selected -> lists_intersect(summary.tags, selected)
  }
  title_match && day_match && target_group_match && tag_match
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
