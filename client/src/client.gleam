import component
import formal/form.{type Form}
import g18n.{type Translator}
import g18n/locale
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration
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
import shared/event as event_dates
import shared/model.{
  type Activity, type ActivitySpots, type ActivityStatus,
  type ActivityStatusEntry, type ActivitySummary, type ActivityTag, type Booking,
  type BookingSlot, type GroupCount, type Location, type TargetGroup, Booked,
  Favourited, NotInterested,
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
  |> g18n.add_translation("activity.full", "Full")
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
  |> g18n.add_translation("app_bar.activity_edit", "Edit activity")
  |> g18n.add_translation("app_bar.manage_activities", "Manage activities")
  |> g18n.add_translation("manage.new_activity", "New activity")
  |> g18n.add_translation("form.error.required", "Must not be blank")
  |> g18n.add_translation("form.error.int", "Must be a number")
  |> g18n.add_translation(
    "form.error.datetime",
    "Must be a valid date and time",
  )
  |> g18n.add_translation("form.error.invalid", "Invalid value")
  |> g18n.add_translation("app_bar.activity_bookings", "Bookings")
  |> g18n.add_translation("app_bar.beach_bus_bookings", "Beach bus bookings")
  |> g18n.add_translation(
    "app_bar.climbing_wall_bookings",
    "Climbing wall bookings",
  )
  |> g18n.add_translation("overview.fully_booked", "Fully booked!")
  |> g18n.add_translation("overview.empty", "No bookings for this day.")
  |> g18n.add_translation("overview.refresh", "Refresh")
  |> g18n.add_translation("activity.booked", "Booked")
  |> g18n.add_translation("activity.needs_booking", "Needs booking")
  |> g18n.add_translation("activity.called_off", "Called off")
  |> g18n.add_translation("activity.show_bookings", "Show bookings")
  |> g18n.add_translation("edit.lang_sv", "Swedish")
  |> g18n.add_translation("edit.lang_en", "English")
  |> g18n.add_translation("edit.name", "Name")
  |> g18n.add_translation("edit.description", "Description")
  |> g18n.add_translation("edit.max_attendees", "Max attendees")
  |> g18n.add_translation("edit.start_time", "Start time")
  |> g18n.add_translation("edit.end_time", "End time")
  |> g18n.add_translation("edit.location", "Location")
  |> g18n.add_translation("edit.location_none", "No location")
  |> g18n.add_translation("edit.location_search", "Search location")
  |> g18n.add_translation("edit.call_off", "Call off")
  |> g18n.add_translation("edit.cancel", "Cancel")
  |> g18n.add_translation("edit.save", "Save")
  |> g18n.add_translation("edit.reason", "Reason")
  |> g18n.add_translation("edit.call_off_title", "Call off activity")
  |> g18n.add_translation("edit.confirm_call_off", "Yes, call off")
  |> g18n.add_translation("booking.responsible_name", "Responsible adult")
  |> g18n.add_translation("booking.phone_number", "Phone number")
  |> g18n.add_translation("booking.group_free_text", "Group / patrol")
  |> g18n.add_translation("booking.participant_count", "Number of participants")
  |> g18n.add_translation("booking.count_min", "At least 1 participant")
  |> g18n.add_translation("booking.count_max", "Only {count} spots left")
  |> g18n.add_translation("booking.submit", "Save")
  |> g18n.add_translation("booking.cancel", "Cancel")
  |> g18n.add_translation("booking.submitting", "Saving booking...")
  |> g18n.add_translation("booking.change", "Change booking")
  |> g18n.add_translation("booking.unbook", "Cancel booking")
  |> g18n.add_translation("booking.confirm_unbook", "Yes, cancel")
  |> g18n.add_translation("bookings.heading", "Bookings")
  |> g18n.add_translation("bookings.loading", "Loading bookings...")
  |> g18n.add_translation("bookings.empty", "No bookings yet.")
  |> g18n.add_translation("bookings.unknown_group", "Unknown group")
  |> g18n.add_translation(
    "bookings.spots_filled",
    "{booked} / {max} spots filled",
  )
  |> g18n.add_translation("bookings.participants.one", "{count} person")
  |> g18n.add_translation("bookings.participants.other", "{count} people")
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
  |> g18n.add_translation(
    "error.call_off_activity",
    "Failed to call off activity",
  )
  |> g18n.add_translation("error.delete_activity", "Failed to delete activity")
  |> g18n.add_translation("error.create_booking", "Failed to create booking")
  |> g18n.add_translation("error.update_booking", "Failed to update booking")
  |> g18n.add_translation("error.load_bookings", "Failed to load bookings")
  |> g18n.add_translation(
    "error.booking_full",
    "This activity is full — not enough spots left",
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
  |> g18n.add_translation("activity.full", "Fullbokad")
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
  |> g18n.add_translation("app_bar.activity_edit", "Redigera aktivitet")
  |> g18n.add_translation("app_bar.manage_activities", "Hantera aktiviteter")
  |> g18n.add_translation("manage.new_activity", "Ny aktivitet")
  |> g18n.add_translation("form.error.required", "Får inte vara tomt")
  |> g18n.add_translation("form.error.int", "Måste vara ett tal")
  |> g18n.add_translation(
    "form.error.datetime",
    "Måste vara giltig datum och tid",
  )
  |> g18n.add_translation("form.error.invalid", "Ogiltigt värde")
  |> g18n.add_translation("app_bar.activity_bookings", "Bokningar")
  |> g18n.add_translation("app_bar.beach_bus_bookings", "Bokningar badbuss")
  |> g18n.add_translation(
    "app_bar.climbing_wall_bookings",
    "Bokningar klättervägg",
  )
  |> g18n.add_translation("overview.fully_booked", "Fullbokat!")
  |> g18n.add_translation("overview.empty", "Inga bokningar den här dagen.")
  |> g18n.add_translation("overview.refresh", "Uppdatera")
  |> g18n.add_translation("activity.booked", "Bokad")
  |> g18n.add_translation("activity.needs_booking", "Behöver bokas")
  |> g18n.add_translation("activity.called_off", "Inställd")
  |> g18n.add_translation("activity.show_bookings", "Visa bokningar")
  |> g18n.add_translation("edit.lang_sv", "Svenska")
  |> g18n.add_translation("edit.lang_en", "Engelska")
  |> g18n.add_translation("edit.name", "Namn")
  |> g18n.add_translation("edit.description", "Beskrivning")
  |> g18n.add_translation("edit.max_attendees", "Max antal deltagare")
  |> g18n.add_translation("edit.start_time", "Starttid")
  |> g18n.add_translation("edit.end_time", "Sluttid")
  |> g18n.add_translation("edit.location", "Plats")
  |> g18n.add_translation("edit.location_none", "Ingen plats")
  |> g18n.add_translation("edit.location_search", "Sök plats")
  |> g18n.add_translation("edit.call_off", "Ställ in")
  |> g18n.add_translation("edit.cancel", "Avbryt")
  |> g18n.add_translation("edit.save", "Spara")
  |> g18n.add_translation("edit.reason", "Anledning")
  |> g18n.add_translation("edit.call_off_title", "Ställ in aktivitet")
  |> g18n.add_translation("edit.confirm_call_off", "Ja, ställ in")
  |> g18n.add_translation("booking.responsible_name", "Ansvarig ledare")
  |> g18n.add_translation("booking.phone_number", "Telefonnummer")
  |> g18n.add_translation("booking.group_free_text", "Grupp / patrull")
  |> g18n.add_translation("booking.participant_count", "Antal deltagare")
  |> g18n.add_translation("booking.count_min", "Minst 1 deltagare")
  |> g18n.add_translation("booking.count_max", "Endast {count} platser kvar")
  |> g18n.add_translation("booking.submit", "Spara")
  |> g18n.add_translation("booking.cancel", "Avbryt")
  |> g18n.add_translation("booking.submitting", "Sparar bokning...")
  |> g18n.add_translation("booking.change", "Ändra bokning")
  |> g18n.add_translation("booking.unbook", "Avboka")
  |> g18n.add_translation("booking.confirm_unbook", "Ja, avboka")
  |> g18n.add_translation("bookings.heading", "Bokningar")
  |> g18n.add_translation("bookings.loading", "Laddar bokningar...")
  |> g18n.add_translation("bookings.empty", "Inga bokningar än.")
  |> g18n.add_translation("bookings.unknown_group", "Okänd grupp")
  |> g18n.add_translation(
    "bookings.spots_filled",
    "{booked} / {max} platser fyllda",
  )
  |> g18n.add_translation("bookings.participants.one", "{count} person")
  |> g18n.add_translation("bookings.participants.other", "{count} personer")
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
    "error.call_off_activity",
    "Kunde inte ställa in aktiviteten",
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
  |> g18n.add_translation("error.load_bookings", "Kunde inte ladda bokningarna")
  |> g18n.add_translation(
    "error.booking_full",
    "Aktiviteten är fullbokad — inte tillräckligt med platser kvar",
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

/// The outcome of a (conditional) list fetch, derived from the HTTP response in
/// the effect handler so `update` never touches raw responses.
///  - `WindowLoaded`: a `200` with decoded summaries and the new `ETag` (if the
///    server sent one).
///  - `WindowUnchanged`: a `304` — the cached window is still current.
///  - `WindowFailed`: a network error, non-success status, or decode failure.
pub type WindowResult {
  WindowLoaded(summaries: List(ActivitySummary), etag: Option(String))
  WindowUnchanged
  WindowFailed
}

/// Identity of a cached activity list: which source, which day (`Some` for the
/// day-windowed browse tabs, `None` for the all-days Favourites view), and
/// whether the manager call-off superset is included. Both the id window and
/// its revalidation ETag are keyed by this, so each `(tab, day, view)` caches
/// and revalidates independently — switching day is as cheap as switching tabs.
pub type WindowKey =
  #(ActivityListSource, Option(calendar.Date), Bool)

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
  CallOffActivityFailed
  DeleteActivityFailed
  CreateBookingFailed
  UpdateBookingFailed
  BookingCapacityExceeded
  LoadBookingsFailed
}

fn app_error_key(error: AppError) -> String {
  case error {
    LoadActivitiesFailed -> "error.load_activities"
    LoadActivityFailed -> "error.load_activity"
    CreateActivityFailed -> "error.create_activity"
    UpdateActivityFailed -> "error.update_activity"
    CallOffActivityFailed -> "error.call_off_activity"
    DeleteActivityFailed -> "error.delete_activity"
    CreateBookingFailed -> "error.create_booking"
    UpdateBookingFailed -> "error.update_booking"
    BookingCapacityExceeded -> "error.booking_full"
    LoadBookingsFailed -> "error.load_bookings"
  }
}

pub type EditState {
  /// The activity is being (re)fetched before the form can open. Reached on
  /// navigation to `/activities/:id/edit`; replaced by `EditReady` once the
  /// fetch returns.
  EditLoading
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

/// Which language variant of the activity's bilingual fields the edit form is
/// currently showing. Toggled via the segmented control at the top of the form;
/// the inactive language's inputs stay mounted (hidden) so their values are
/// preserved across a toggle and still submitted.
pub type EditLanguage {
  EditSwedish
  EditEnglish
}

/// Transient, edit-page-scoped view state. Kept on the `Model` (not inside the
/// multi-variant `EditState`, whose record-update spreads Gleam forbids) so it
/// can be updated with a plain record update. Reset each time the edit form
/// opens.
pub type EditUi {
  EditUi(
    /// Which language variant of the bilingual fields is currently shown.
    language: EditLanguage,
    /// Whether the "call off activity" (ställ in) confirmation modal is open.
    cancel_open: Bool,
    /// Reason for calling off the activity, entered in the modal. UI-only for
    /// now — not persisted.
    cancel_reason: String,
    /// The activity's chosen location, or `None` for no location. Working state
    /// for the location picker; sent as `location_id` on save. Seeded from the
    /// activity when the edit form opens, and `None` on the create form.
    location_id: Option(Uuid),
    /// Free-text filter typed into the location combobox (case-insensitive match
    /// on the localized name). Shown in the field while the dropdown is open;
    /// reset when a location is chosen.
    location_query: String,
    /// Whether the location combobox's dropdown list is open.
    location_open: Bool,
  )
}

/// The edit form's default view state: Swedish variant, call-off modal closed,
/// no location chosen, empty location filter, dropdown closed.
pub fn default_edit_ui() -> EditUi {
  EditUi(
    language: EditSwedish,
    cancel_open: False,
    cancel_reason: "",
    location_id: None,
    location_query: "",
    location_open: False,
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
    more_open: Bool,
    target_groups: List(TargetGroup),
    tags: List(Uuid),
  )
}

pub fn default_filters() -> ListFilters {
  ListFilters(
    search: "",
    tab: TabActivities,
    more_open: False,
    target_groups: [],
    tags: [],
  )
}

/// Tabs in display order; index is used for the segmented control.
fn list_tabs() -> List(ActivitiesFilterTab) {
  [TabActivities, TabBeachBus, TabClimbingWall, TabFavourites]
}

/// Tabs shown for a given list mode. The management list has no per-user
/// favourites, so it drops that tab; the kept tabs preserve the browse order
/// (and their indices), so `tab_index`/`tab_from_index` still line up.
pub fn list_tabs_for(mode: ListMode) -> List(ActivitiesFilterTab) {
  case mode {
    BrowseList -> list_tabs()
    ManageList -> [TabActivities, TabBeachBus, TabClimbingWall]
  }
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

/// Which variant of the activities list is showing. The two share the entire
/// list view (top bar, tabs, filters, grouping, states); they differ only per
/// card: `BrowseList` links to the detail page with a favourite heart,
/// `ManageList` links to the edit page with an edit pen. `ManageList` is reached
/// from the role-gated "Manage activities" item in the shell's "More" menu.
pub type ListMode {
  BrowseList
  ManageList
}

/// A kind of recurring activity that gets its own booking-overview page
/// (Badbuss / Klättervägg). Both pages share one view, differing only in which
/// slots they load and their heading; the kind also maps to the server's
/// `recurring_activity_kind` and picks the overview endpoint.
pub type RecurringKind {
  BeachBus
  ClimbingWall
}

pub type Page {
  ActivitiesListPage(filters: ListFilters, mode: ListMode)
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
  /// The management-only view of every booking for one activity. The bookings
  /// list is per-route state; the activity header (title/time/spots) reads from
  /// the shared `details` + `spots` caches, so it can't drift from the summary.
  ActivityBookingsPage(id: Uuid, bookings: RemoteData(List(Booking)))
  /// Today's-bookings overview for a recurring activity kind (Badbuss /
  /// Klättervägg): every live slot for `kind`, grouped by kår, filtered to
  /// `selected_day` at view time (default today). Auto-refreshes on a timer.
  /// Reached from the role-gated menu items in the shell's "More" menu; each
  /// card drills into that slot's full `ActivityBookingsPage`.
  RecurringBookingsPage(
    kind: RecurringKind,
    selected_day: calendar.Date,
    overview: RemoteData(List(BookingSlot)),
  )
  NotFoundPage
}

/// The detail-only fields of an activity — everything NOT already carried by
/// its `ActivitySummary`. Fetched lazily when a detail page opens and cached in
/// `Model.details`, keyed by activity id. Storing only these fields (rather than
/// a full `Activity`) keeps the summary in exactly one place (`Model.activities`),
/// so a list refetch can never leave an open detail view showing stale summary
/// fields.
pub type ActivityDetail {
  ActivityDetail(description: model.BilingualString, location: Option(Location))
}

pub type Model {
  Model(
    page: Page,
    translator: Translator,
    // Entity cache: one slim summary per activity, hydrated/overwritten by
    // EVERY list response (browse pages, beach-bus, climbing-wall, favourited).
    activities: Dict(Uuid, ActivitySummary),
    // Ordered id windows keyed by fetch identity (source + day + include-call-
    // offs). Each browse tab/day and the all-days Favourites view cache
    // independently, so switching day shows the cached list instantly and
    // revalidates in the background exactly like switching tabs. The Favourites
    // window (`favourites_key`) drives that tab's fetch state + hydration;
    // membership there is DERIVED from `statuses`, not the window ids.
    windows: Dict(WindowKey, RemoteData(List(Uuid))),
    // Strong ETag of the last successful response per window, sent back as
    // `If-None-Match` to revalidate; a `304` means that window is still current.
    etags: Dict(WindowKey, String),
    // Today clamped into the event range — the browse tabs' default day.
    today: calendar.Date,
    // The day shared by the browse tabs (Aktiviteter / Badbuss / Klättervägg),
    // lifted out of the page so it survives navigation. `None` resolves to
    // `today` (browse has no "all days" option).
    browse_day_filter: Option(calendar.Date),
    // Favourites' own day, independent of the browse tabs. `None` = "all days"
    // (its default); a pick narrows the all-days list client-side.
    favourites_day_filter: Option(calendar.Date),
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
    // Location vocabulary, keyed by id, fetched once from /api/locations. Feeds
    // the create/edit form's location picker. Empty until loaded (and if the
    // fetch fails), in which case the picker shows only the "no location" option.
    locations: Dict(Uuid, Location),
    // The current user's roles, gating manage-only UI (edit, view bookings).
    roles: List(Role),
    // Transient view state for the edit form (active language, call-off reason
    // reveal). Kept here rather than in the multi-variant `EditState` so it can
    // be updated with a plain record update; reset whenever the form opens.
    edit_ui: EditUi,
  )
}

/// Access roles the client gates UI on, parsed from the user's Keycloak roles
/// on the `j26-booking` client. Only roles the UI acts on are modelled (plus
/// `Admin`, which implies all authority — mirroring the server's
/// `web.require_role`); the strings match the server's `web.Role`.
pub type Role {
  ManageActivities
  BookingsRead
  Admin
}

fn role_from_string(raw: String) -> Result(Role, Nil) {
  case raw {
    "activities:manage" -> Ok(ManageActivities)
    "bookings:read" -> Ok(BookingsRead)
    "admin" -> Ok(Admin)
    _ -> Error(Nil)
  }
}

/// Whether the user holds `role`. `Admin` implies every role, matching the
/// server's `web.require_role`.
fn has_role(model: Model, role: Role) -> Bool {
  list.contains(model.roles, role) || list.contains(model.roles, Admin)
}

/// Whether the user may view an activity's bookings, gating the "Show bookings"
/// action. Mirrors the server's `bookings:read` guard; `activities:manage` and
/// `Admin` also qualify.
fn can_view_bookings(model: Model) -> Bool {
  has_role(model, BookingsRead) || has_role(model, ManageActivities)
}

pub fn tab_source(tab: ActivitiesFilterTab) -> ActivityListSource {
  case tab {
    TabActivities -> SourceActivities
    TabBeachBus -> SourceBeachBus
    TabClimbingWall -> SourceClimbingWall
    TabFavourites -> SourceFavourites
  }
}

/// The `RemoteData` cached for a window key (`NotAsked` if never fetched).
pub fn window_remote(model: Model, key: WindowKey) -> RemoteData(List(Uuid)) {
  dict.get(model.windows, key) |> result.unwrap(NotAsked)
}

pub fn set_window_remote(
  model: Model,
  key: WindowKey,
  remote: RemoteData(List(Uuid)),
) -> Model {
  Model(..model, windows: dict.insert(model.windows, key, remote))
}

/// Drop every cached browse window (all sources/days/views except Favourites)
/// so the next view refetches. Used after a create, whose day and special-tab
/// kind we can't map to a single window to update in place.
fn invalidate_browse_windows(
  windows: Dict(WindowKey, RemoteData(List(Uuid))),
) -> Dict(WindowKey, RemoteData(List(Uuid))) {
  dict.filter(windows, fn(key, _) { key.0 == SourceFavourites })
}

/// The all-days Favourites window key. The favourited endpoint spans every day
/// and always includes call-offs, so its identity carries no day and no
/// call-off flag.
pub fn favourites_key() -> WindowKey {
  #(SourceFavourites, None, False)
}

/// The fetch identity for a source: browse sources window by the shared browse
/// day (`browse_day_filter`, else the clamped "today"); Favourites spans all
/// days regardless of its own day pick (which narrows client-side only).
/// `include_call_offs` is role-derived.
pub fn window_key_for(model: Model, source: ActivityListSource) -> WindowKey {
  case source {
    SourceFavourites -> favourites_key()
    _ -> #(
      source,
      Some(option.unwrap(model.browse_day_filter, model.today)),
      source_include_call_offs(model, source),
    )
  }
}

/// The day a tab currently resolves to, read from the Model's per-view day
/// fields (so it survives page rebuilds): Favourites uses its own day (`None` =
/// all days, its default); the browse tabs share `browse_day_filter`, defaulting
/// to the clamped `today` (browse has no "all days").
pub fn effective_day(
  model: Model,
  tab: ActivitiesFilterTab,
) -> Option(calendar.Date) {
  case tab {
    TabFavourites -> model.favourites_day_filter
    _ -> Some(option.unwrap(model.browse_day_filter, model.today))
  }
}

/// Show-then-revalidate a window: an unfetched window flips to `Loading` and
/// fetches; an already-loaded window refetches conditionally in the background
/// (a `304` keeps what's shown), so revisiting a tab/day/page is cheap and stays
/// fresh without blanking to a spinner. A window mid-flight or awaiting retry is
/// left alone.
pub fn load_or_revalidate(
  model: Model,
  key: WindowKey,
) -> #(Model, Effect(Msg)) {
  case window_remote(model, key) {
    NotAsked -> #(
      set_window_remote(model, key, Loading),
      fetch_window(model, key),
    )
    Loaded(_) -> #(model, fetch_window(model, key))
    Loading | Failed(_) -> #(model, effect.none())
  }
}

/// Resolves a tab into the `RemoteData` of summaries to render. Browse tabs map
/// their id window through the entity cache (dropping ids not yet cached).
/// Favourites derives membership from the complete `statuses` map; its
/// `favourited` fetch only supplies hydration + loading/error state.
pub fn tab_summaries(
  model: Model,
  filters: ListFilters,
  mode: ListMode,
) -> RemoteData(List(ActivitySummary)) {
  case filters.tab {
    TabFavourites -> {
      // Membership is derived from the complete `statuses` map; the favourites
      // window only supplies hydration (summaries for fav/booked items not yet in
      // the cache, e.g. beach-bus/climbing-wall slots) + the first-load state.
      let derived =
        model.statuses
        |> dict.keys
        |> list.filter(fn(id) { is_favourited(status_of(model.statuses, id)) })
        |> list.filter_map(fn(id) { dict.get(model.activities, id) })
      case derived, window_remote(model, favourites_key()) {
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
      case
        window_remote(model, window_key_for(model, tab_source(filters.tab)))
      {
        NotAsked -> NotAsked
        Loading -> Loading
        Failed(err) -> Failed(err)
        Loaded(ids) -> {
          let summaries =
            list.filter_map(ids, fn(id) { dict.get(model.activities, id) })
          // Browse lists never render called-off activities — they surface only
          // in the management list. Booked/favourited users still reach their
          // called-off activities via the Favourites tab and the detail page.
          let visible = case mode {
            BrowseList ->
              list.filter(summaries, fn(s) { option.is_none(s.cancellation) })
            ManageList -> summaries
          }
          Loaded(visible)
        }
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
    ActivityDetailPage(id, _)
    | ActivityEditPage(id, _)
    | ActivityBookingsPage(id, _) ->
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
    cancellation: a.cancellation,
  )
}

/// Extract the detail-only fields from a full activity.
fn to_detail(a: Activity) -> ActivityDetail {
  ActivityDetail(description: a.description, location: a.location)
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
    tags: summary.tags,
    target_groups: summary.target_groups,
    cancellation: summary.cancellation,
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

/// Drop an id from a loaded id window (no-op while not loaded).
pub fn remove_id(
  remote: RemoteData(List(Uuid)),
  id: Uuid,
) -> RemoteData(List(Uuid)) {
  use ids <- map_loaded(remote)
  list.filter(ids, fn(x) { x != id })
}

/// `max_participants` caps the participant count (the spots the user may claim,
/// already accounting for their own booking on an edit). `None` leaves it
/// uncapped client-side (uncapped activity, or the booked count is unknown) —
/// the server still enforces the real limit.
fn new_booking_form(
  translator: Translator,
  max_participants: Option(Int),
) -> Form(BookingFormFields) {
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
    use participant_count <- form.field(
      "participant_count",
      form.parse_int
        |> form.check(participant_count_check(translator, max_participants)),
    )
    form.success(BookingFormFields(
      group_free_text:,
      responsible_name:,
      phone_number:,
      participant_count:,
    ))
  })
  |> form.add_string("participant_count", "1")
}

/// Validates a submitted participant count: at least 1, and within the cap when
/// one is known. Returns a translated message on failure.
fn participant_count_check(
  translator: Translator,
  max_participants: Option(Int),
) -> fn(Int) -> Result(Int, String) {
  fn(count) {
    case count < 1, max_participants {
      True, _ -> Error(g18n.translate(translator, "booking.count_min"))
      False, Some(max) if count > max ->
        Error(g18n.translate_with_params(
          translator,
          "booking.count_max",
          g18n.new_format_params()
            |> g18n.add_param("count", int.to_string(max)),
        ))
      False, _ -> Ok(count)
    }
  }
}

/// The participant-count cap for a fresh booking, derived from the activity cap
/// and current booked count. `None` when uncapped or the count is unknown.
fn booking_cap(
  max_attendees: Option(Int),
  spots_booked: Option(Int),
) -> Option(Int) {
  case model.spots_remaining(max_attendees, spots_booked) {
    model.Remaining(remaining) -> Some(remaining)
    model.Unlimited | model.UnknownSpots -> None
  }
}

fn empty_booking_fields() -> BookingFormFields {
  BookingFormFields(
    group_free_text: "",
    responsible_name: "",
    phone_number: "",
    participant_count: 1,
  )
}

fn booking_form_from(
  b: Booking,
  translator: Translator,
  max_participants: Option(Int),
) -> Form(BookingFormFields) {
  new_booking_form(translator, max_participants)
  |> form.add_string("group_free_text", b.group_free_text)
  |> form.add_string("responsible_name", b.responsible_name)
  |> form.add_string("phone_number", b.phone_number)
  |> form.add_string("participant_count", int.to_string(b.participant_count))
}

/// Classifies a failed booking request: a `409` means the server rejected it
/// for capacity (e.g. a race the client's cap didn't catch); anything else is
/// the generic `fallback` error.
fn booking_error(error: rsvp.Error, fallback: AppError) -> AppError {
  case error {
    rsvp.HttpError(response) if response.status == 409 ->
      BookingCapacityExceeded
    _ -> fallback
  }
}

/// After a capacity rejection, refresh the activity's booked count so the cap
/// reflects reality; other errors need no refresh.
fn capacity_refresh(app_error: AppError, id: Uuid) -> Effect(Msg) {
  case app_error {
    BookingCapacityExceeded -> fetch_activity_spots(id)
    _ -> effect.none()
  }
}

/// Cap for the booking form on activity `id`, given the booking `mode`.
fn booking_cap_for(model: Model, id: Uuid, mode: BookingMode) -> Option(Int) {
  let max_attendees = case detail_of(model, id) {
    Loaded(activity) -> activity.max_attendees
    _ -> None
  }
  let spots_booked = dict.get(model.spots, id) |> option.from_result
  cap_for_mode(max_attendees, spots_booked, status_of(model.statuses, id), mode)
}

/// The participant cap for a given booking mode. On an edit the booking's own
/// participants are added back, since they're already in the activity's booked
/// count.
fn cap_for_mode(
  max_attendees: Option(Int),
  spots_booked: Option(Int),
  status: ActivityStatus,
  mode: BookingMode,
) -> Option(Int) {
  let base = booking_cap(max_attendees, spots_booked)
  case mode, base {
    BookingEdit(booking_id), Some(remaining) ->
      case booking_of(status) {
        Some(b) if b.id == booking_id -> Some(remaining + b.participant_count)
        _ -> base
      }
    _, _ -> base
  }
}

fn activity_form() -> Form(ActivityForm) {
  form.new({
    use title <- form.field("title", form.parse_string |> form.check_not_empty)
    use title_en <- form.field(
      "title_en",
      form.parse_string |> form.check_not_empty,
    )
    use description <- form.field(
      "description",
      form.parse_string |> form.check_not_empty,
    )
    use description_en <- form.field(
      "description_en",
      form.parse_string |> form.check_not_empty,
    )
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

/// Build a fresh edit state from a just-fetched activity: seed the form and the
/// working tag/målgrupp selections from it.
fn edit_ready_from_activity(activity: Activity) -> EditState {
  EditReady(
    activity:,
    form: form_from_activity(activity),
    submit_error: None,
    tags: activity.tags,
    target_groups: activity.target_groups,
  )
}

// Field setters for `EditReady`. Gleam forbids record-update spread on a
// multi-variant type, so each rebuilds the record explicitly; a loading state is
// left untouched. These keep the update handlers to one-liners.

fn edit_with_error(state: EditState, error: Option(AppError)) -> EditState {
  case state {
    EditLoading -> state
    EditReady(activity:, form:, tags:, target_groups:, submit_error: _) ->
      EditReady(activity:, form:, submit_error: error, tags:, target_groups:)
  }
}

fn edit_with_form(state: EditState, form: Form(ActivityForm)) -> EditState {
  case state {
    EditLoading -> state
    EditReady(activity:, submit_error:, tags:, target_groups:, form: _) ->
      EditReady(activity:, form:, submit_error:, tags:, target_groups:)
  }
}

fn edit_with_tags(state: EditState, tags: List(Uuid)) -> EditState {
  case state {
    EditLoading -> state
    EditReady(activity:, form:, submit_error:, target_groups:, tags: _) ->
      EditReady(activity:, form:, submit_error:, tags:, target_groups:)
  }
}

fn edit_with_target_groups(
  state: EditState,
  target_groups: List(TargetGroup),
) -> EditState {
  case state {
    EditLoading -> state
    EditReady(activity:, form:, submit_error:, tags:, target_groups: _) ->
      EditReady(activity:, form:, submit_error:, tags:, target_groups:)
  }
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
    ActivitiesListPage(_, BrowseList) ->
      Some(g18n.translate(translator, "app_bar.activities_list"))
    ActivitiesListPage(_, ManageList) ->
      Some(g18n.translate(translator, "app_bar.manage_activities"))
    ActivityDetailPage(_, _) ->
      Some(g18n.translate(translator, "app_bar.activity_detail"))
    ActivityNewPage(..) ->
      Some(g18n.translate(translator, "app_bar.activity_new"))
    ActivityBookingsPage(_, _) ->
      Some(g18n.translate(translator, "app_bar.activity_bookings"))
    ActivityEditPage(_, _) ->
      Some(g18n.translate(translator, "app_bar.activity_edit"))
    RecurringBookingsPage(BeachBus, _, _) ->
      Some(g18n.translate(translator, "app_bar.beach_bus_bookings"))
    RecurringBookingsPage(ClimbingWall, _, _) ->
      Some(g18n.translate(translator, "app_bar.climbing_wall_bookings"))
    NotFoundPage -> None
  }
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let translator = translator_for(get_html_lang())

  let #(page, page_effect) = case modem.initial_uri() {
    Ok(uri) -> uri_to_page(uri, dict.new())
    Error(_) -> #(
      ActivitiesListPage(default_filters(), BrowseList),
      effect.none(),
    )
  }

  let today = event_dates.clamp_to_event(today())
  // The default Activities window (today, non-manager view) loads immediately;
  // every other tab/day loads lazily on first open. Roles are empty here, so a
  // manager's call-off superset (a distinct key) loads once /api/me returns.
  let initial_key = #(SourceActivities, Some(today), False)

  let model =
    Model(
      page:,
      translator:,
      activities: dict.new(),
      windows: dict.from_list([#(initial_key, Loading)]),
      etags: dict.new(),
      today:,
      // Browse defaults to today (via `None`); Favourites to all days (`None`).
      browse_day_filter: None,
      favourites_day_filter: None,
      details: seed_detail_loading(dict.new(), page),
      statuses: dict.new(),
      spots: dict.new(),
      activity_tags: dict.new(),
      locations: dict.new(),
      // Empty until /api/me returns; the role-gated UI reveals once loaded.
      roles: [],
      edit_ui: default_edit_ui(),
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
      start_refresh_timer(),
      fetch_window(model, initial_key),
      fetch_spots(),
      fetch_activity_tags(),
      fetch_locations(),
      page_effect,
      // Always attempt; a 401 (anonymous user) leaves the status dict empty.
      fetch_statuses(),
      // Load the user's roles; a 401 leaves roles empty (restricted view).
      fetch_me(),
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
  // API responses. `ApiReturnedActivityWindow` carries the `WindowKey` the
  // request used (to store the id window + its ETag) and a `WindowResult` — the
  // raw HTTP response is interpreted in the effect handler so `update` stays pure.
  ApiReturnedActivityWindow(WindowKey, WindowResult)
  ApiReturnedActivity(Uuid, Result(Activity, rsvp.Error))
  ApiReturnedMe(Result(List(Role), rsvp.Error))
  ApiReturnedStatuses(Result(List(ActivityStatusEntry), rsvp.Error))
  ApiReturnedActivitySpots(Result(List(ActivitySpots), rsvp.Error))
  ApiReturnedActivitySpotsOne(Uuid, Result(Int, rsvp.Error))
  ApiReturnedActivityTags(Result(List(ActivityTag), rsvp.Error))
  ApiReturnedLocations(Result(List(Location), rsvp.Error))
  ApiCreatedActivity(Result(Activity, rsvp.Error))
  ApiUpdatedActivity(Result(Activity, rsvp.Error))
  ApiCancelledActivity(Result(Activity, rsvp.Error))
  ApiDeletedActivity(Uuid, Result(Nil, rsvp.Error))
  ApiCreatedBooking(Result(Booking, rsvp.Error))
  ApiUpdatedBooking(Result(Booking, rsvp.Error))
  ApiDeletedBooking(Uuid, Uuid, Result(Nil, rsvp.Error))
  ApiReturnedBookings(Uuid, Result(List(Booking), rsvp.Error))
  ApiToggledFavourite(Uuid, Bool, Result(Nil, rsvp.Error))
  // Form submissions
  UserSubmittedCreateForm(Result(ActivityForm, Form(ActivityForm)))
  UserSubmittedEditForm(Result(ActivityForm, Form(ActivityForm)))
  UserSubmittedBookingForm(Result(BookingFormFields, Form(BookingFormFields)))
  // User actions
  UserClickedShowBookings
  UserClickedNewActivity
  UserClickedDelete
  UserClickedCancelEdit
  UserSelectedEditLanguage(EditLanguage)
  UserToggledCallOff
  UserEditedCallOffReason(String)
  UserClickedConfirmCallOff
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
  // Location picker (create/edit form)
  UserSelectedLocation(Option(Uuid))
  UserSearchedLocation(String)
  UserOpenedLocationDropdown
  UserClosedLocationDropdown
  // Recurring-activity booking overview (Badbuss / Klättervägg)
  ApiReturnedRecurringBookings(
    RecurringKind,
    Result(List(BookingSlot), rsvp.Error),
  )
  UserSelectedOverviewDay(Option(calendar.Date))
  UserClickedRefreshOverview
  UserClickedSlot(Uuid)
  // Fires once a minute; refetches the overview when one is open (no-op else).
  TimerTicked
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnRouteChange(uri) -> {
      let #(page, page_effect) = uri_to_page(uri, model.details)
      let details = seed_detail_loading(model.details, page)
      // Opening the create form resets the shared form UI state (language,
      // call-off); the edit form resets it when its fetch returns instead.
      let edit_ui = case page {
        ActivityNewPage(..) -> default_edit_ui()
        _ -> model.edit_ui
      }
      let title_effect = case app_bar_title(model.translator, page) {
        Some(title) -> set_app_bar_title(title)
        None -> effect.none()
      }
      let nav_effect = notify_navigation(uri)
      let model = Model(..model, page:, details:, edit_ui:)
      // Entering a list page revalidates the active tab (cheap 304 when
      // unchanged), so a returning view stays fresh without a blocking reload.
      let #(model, list_effect) = case page {
        ActivitiesListPage(filters, _) ->
          load_or_revalidate(
            model,
            window_key_for(model, tab_source(filters.tab)),
          )
        _ -> #(model, effect.none())
      }
      #(
        model,
        effect.batch([page_effect, title_effect, nav_effect, list_effect]),
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

    ApiReturnedActivityWindow(key, WindowLoaded(items, etag)) -> {
      let activities = hydrate(model.activities, items)
      let ids = list.map(items, fn(s) { s.id })
      let etags = case etag {
        Some(tag) -> dict.insert(model.etags, key, tag)
        None -> model.etags
      }
      #(
        set_window_remote(Model(..model, activities:, etags:), key, Loaded(ids)),
        effect.none(),
      )
    }

    // A 304: the cached window is still current, so leave it (and its ETag)
    // untouched.
    ApiReturnedActivityWindow(_key, WindowUnchanged) -> #(model, effect.none())

    ApiReturnedActivityWindow(key, WindowFailed) -> #(
      set_window_remote(model, key, Failed(LoadActivitiesFailed)),
      effect.none(),
    )

    ApiReturnedActivity(id, Ok(activity)) -> {
      // A detail fetch carries the whole activity, so refresh the summary too —
      // this both keeps the two caches in sync and populates the summary on
      // direct navigation to an activity we never listed. If we were waiting on
      // this fetch to open the edit form, seed the form now (with fresh UI state).
      let #(page, edit_ui) = case model.page {
        ActivityEditPage(edit_id, EditLoading) if edit_id == id -> #(
          ActivityEditPage(id, edit_ready_from_activity(activity)),
          // Seed the location picker from the activity; other UI state defaults.
          EditUi(
            ..default_edit_ui(),
            location_id: option.map(activity.location, fn(l) { l.id }),
          ),
        )
        _ -> #(model.page, model.edit_ui)
      }
      // The detail fetch carries the full location too; fold it into the cache
      // so the picker can name it even if the bulk /api/locations fetch failed.
      let locations = case activity.location {
        Some(l) -> dict.insert(model.locations, l.id, l)
        None -> model.locations
      }
      #(
        Model(
          ..model,
          activities: dict.insert(model.activities, id, to_summary(activity)),
          details: dict.insert(model.details, id, Loaded(to_detail(activity))),
          locations:,
          page:,
          edit_ui:,
        ),
        effect.none(),
      )
    }

    ApiReturnedActivity(id, Error(_)) -> {
      // A failed load while opening the edit form has nowhere to go — fall back
      // to the not-found page rather than spinning forever.
      let page = case model.page {
        ActivityEditPage(edit_id, EditLoading) if edit_id == id -> NotFoundPage
        _ -> model.page
      }
      #(
        Model(
          ..model,
          details: dict.insert(model.details, id, Failed(LoadActivityFailed)),
          page:,
        ),
        effect.none(),
      )
    }

    ApiReturnedMe(Ok(roles)) -> {
      let model = Model(..model, roles:)
      // Roles gate `include_call_offs`, so once they load re-fetch the visible
      // list: a manager's window upgrades to the call-off superset the manage
      // view needs, and a non-manager just gets a cheap revalidation.
      case model.page {
        ActivitiesListPage(filters, _) ->
          load_or_revalidate(
            model,
            window_key_for(model, tab_source(filters.tab)),
          )
        _ -> #(model, effect.none())
      }
    }

    // 401 / network error -> no roles -> restricted view.
    ApiReturnedMe(Error(_)) -> #(Model(..model, roles: []), effect.none())

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

    ApiReturnedLocations(Ok(locations)) -> {
      let locations =
        list.fold(locations, dict.new(), fn(acc, location) {
          dict.insert(acc, location.id, location)
        })
      #(Model(..model, locations:), effect.none())
    }

    // Keep the prior vocabulary (empty) on failure; the picker just shows the
    // "no location" option only.
    ApiReturnedLocations(Error(_)) -> #(model, effect.none())

    ApiCreatedActivity(Ok(activity)) -> #(
      Model(
        ..model,
        activities: dict.insert(
          model.activities,
          activity.id,
          to_summary(activity),
        ),
        // The new activity's day and special-tab kind can't be mapped to a
        // single window, so drop the browse windows; the manage list we return
        // to refetches the relevant day.
        windows: invalidate_browse_windows(model.windows),
        details: dict.insert(
          model.details,
          activity.id,
          Loaded(to_detail(activity)),
        ),
      ),
      // Created from the management list, so return there.
      modem.push(api_prefix <> "/activities/manage", None, None),
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

    // A successful save refreshes both caches and returns to the management
    // list it was launched from, matching the create flow and Avbryt.
    ApiUpdatedActivity(Ok(activity)) -> #(
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
      ),
      modem.push(api_prefix <> "/activities/manage", None, None),
    )

    ApiUpdatedActivity(Error(_)) ->
      case model.page {
        ActivityEditPage(id, EditReady(..) as edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              edit_with_error(edit, Some(UpdateActivityFailed)),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    // A successful call-off refreshes both caches (so the cancelled state and
    // reason show immediately) and returns to the management list, matching the
    // save flow.
    ApiCancelledActivity(Ok(activity)) -> #(
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
      ),
      modem.push(api_prefix <> "/activities/manage", None, None),
    )

    ApiCancelledActivity(Error(_)) ->
      case model.page {
        ActivityEditPage(id, EditReady(..) as edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              edit_with_error(edit, Some(CallOffActivityFailed)),
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
        // Drop the id from every cached window so it vanishes everywhere at once.
        windows: dict.map_values(model.windows, fn(_key, remote) {
          remove_id(remote, id)
        }),
        details: dict.delete(model.details, id),
        statuses: dict.delete(model.statuses, id),
      ),
      modem.push(api_prefix <> "/activities", None, None),
    )

    ApiDeletedActivity(_, Error(_)) ->
      case model.page {
        ActivityEditPage(id, EditReady(..) as edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              edit_with_error(edit, Some(DeleteActivityFailed)),
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
          create_activity(
            activity_form,
            tags,
            target_groups,
            model.edit_ui.location_id,
          ),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedCreateForm(Error(f)) ->
      case model.page {
        ActivityNewPage(_, submit_error, tags, target_groups) -> #(
          Model(
            ..model,
            page: ActivityNewPage(f, submit_error, tags, target_groups),
            edit_ui: EditUi(
              ..model.edit_ui,
              language: language_needing_attention(f, model.edit_ui.language),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedEditForm(Ok(activity_form)) ->
      case model.page {
        ActivityEditPage(id, EditReady(tags:, target_groups:, ..)) -> #(
          model,
          update_activity(
            id,
            activity_form,
            tags,
            target_groups,
            model.edit_ui.location_id,
          ),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedEditForm(Error(f)) ->
      case model.page {
        ActivityEditPage(id, EditReady(..) as edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(id, edit_with_form(edit, f)),
            edit_ui: EditUi(
              ..model.edit_ui,
              language: language_needing_attention(f, model.edit_ui.language),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    // The "Visa bokningar" button on the detail page navigates to this
    // activity's bookings list; the route change fires the fetch (uri_to_page).
    UserClickedShowBookings ->
      case model.page {
        ActivityDetailPage(id, _) -> #(
          model,
          modem.push(
            api_prefix <> "/activities/" <> uuid.to_string(id) <> "/bookings",
            None,
            None,
          ),
        )
        _ -> #(model, effect.none())
      }

    // The "New activity" button on the management list: navigate to the create
    // form. The route change opens `ActivityNewPage` (see uri_to_page).
    UserClickedNewActivity -> #(
      model,
      modem.push(api_prefix <> "/activities/new", None, None),
    )

    // "Avbryt" — discard changes. Both edit and create return to the
    // management list they were launched from.
    UserClickedCancelEdit ->
      case model.page {
        ActivityEditPage(..) | ActivityNewPage(..) -> #(
          model,
          modem.push(api_prefix <> "/activities/manage", None, None),
        )
        _ -> #(model, effect.none())
      }

    UserSelectedEditLanguage(language) -> #(
      Model(..model, edit_ui: EditUi(..model.edit_ui, language:)),
      effect.none(),
    )

    // "Ställ in" — open/close the call-off confirmation modal. UI-only for now.
    UserToggledCallOff -> #(
      Model(
        ..model,
        edit_ui: EditUi(
          ..model.edit_ui,
          cancel_open: !model.edit_ui.cancel_open,
        ),
      ),
      effect.none(),
    )

    UserEditedCallOffReason(reason) -> #(
      Model(..model, edit_ui: EditUi(..model.edit_ui, cancel_reason: reason)),
      effect.none(),
    )

    // Confirm the call-off from the modal: persist it via the API. Closes the
    // modal immediately; the reason is kept so it can be shown/retried if the
    // request fails. On success `ApiCancelledActivity(Ok)` refreshes the caches
    // and returns to the management list.
    UserClickedConfirmCallOff ->
      case model.page {
        ActivityEditPage(id, _) -> #(
          Model(..model, edit_ui: EditUi(..model.edit_ui, cancel_open: False)),
          cancel_activity(id, model.edit_ui.cancel_reason),
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
        ActivitiesListPage(filters, mode) -> {
          let tab = tab_from_index(index)
          // Each tab reads its own persistent day (browse tabs share
          // `browse_day_filter`, Favourites its own), so switching tabs just
          // changes the tab and revalidates that tab's resolved window.
          let filters = ListFilters(..filters, tab:)
          let #(model, fetch_effect) =
            load_or_revalidate(model, window_key_for(model, tab_source(tab)))
          #(
            Model(..model, page: ActivitiesListPage(filters, mode)),
            fetch_effect,
          )
        }
        _ -> #(model, effect.none())
      }

    // Picking a day persists it to the current tab's own day field (so it
    // survives navigation and stays independent per view), then revalidates.
    // On a browse tab that fetches the newly-selected day's window (instant from
    // cache + background revalidate); on Favourites the day only narrows the
    // rendered list client-side, so this just revalidates the all-days window.
    UserSelectedDay(d) ->
      case model.page {
        ActivitiesListPage(filters, _) -> {
          let model = case filters.tab {
            // Picking a concrete day on Favourites also moves the browse day
            // there, so switching back to a browse tab lands on the same day;
            // "all days" (`None`) leaves the browse day untouched.
            TabFavourites ->
              case d {
                Some(_) ->
                  Model(..model, favourites_day_filter: d, browse_day_filter: d)
                None -> Model(..model, favourites_day_filter: d)
              }
            _ -> Model(..model, browse_day_filter: d)
          }
          load_or_revalidate(
            model,
            window_key_for(model, tab_source(filters.tab)),
          )
        }
        _ -> #(model, effect.none())
      }

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
        ActivityEditPage(id, EditReady(target_groups:, ..) as edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              edit_with_target_groups(
                edit,
                toggle_member(target_groups, target_group),
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
        ActivityEditPage(id, EditReady(tags:, ..) as edit) -> #(
          Model(
            ..model,
            page: ActivityEditPage(
              id,
              edit_with_tags(edit, toggle_member(tags, tag_id)),
            ),
          ),
          effect.none(),
        )
        _ ->
          update_filters(model, fn(f) {
            ListFilters(..f, tags: toggle_member(f.tags, tag_id))
          })
      }

    // Location combobox: single-select, so a pick replaces the working location
    // (rather than toggling a set). Kept on `edit_ui` since both the create and
    // edit forms read it there. Choosing clears the filter and closes the list.
    UserSelectedLocation(location_id) -> #(
      Model(
        ..model,
        edit_ui: EditUi(
          ..model.edit_ui,
          location_id:,
          location_query: "",
          location_open: False,
        ),
      ),
      effect.none(),
    )

    // Typing filters the list and keeps it open.
    UserSearchedLocation(query) -> #(
      Model(
        ..model,
        edit_ui: EditUi(
          ..model.edit_ui,
          location_query: query,
          location_open: True,
        ),
      ),
      effect.none(),
    )

    // Clicking the field opens the list on a clean filter, so the full list of
    // locations shows.
    UserOpenedLocationDropdown -> {
      // Opening from closed starts on a clean filter so the full list shows; a
      // click while already open (e.g. to move the cursor mid-search) must not
      // wipe what the user has typed.
      let location_query = case model.edit_ui.location_open {
        True -> model.edit_ui.location_query
        False -> ""
      }
      #(
        Model(
          ..model,
          edit_ui: EditUi(..model.edit_ui, location_query:, location_open: True),
        ),
        effect.none(),
      )
    }

    // Blurring the field closes the list. Option clicks fire on `mousedown`,
    // before this blur, so a selection is never lost to the close.
    UserClosedLocationDropdown -> #(
      Model(..model, edit_ui: EditUi(..model.edit_ui, location_open: False)),
      effect.none(),
    )

    // Overview data arrived. Only apply it if we're still on the matching
    // overview page (the user may have navigated away, or switched kind, since
    // the fetch fired). The selected day is preserved.
    ApiReturnedRecurringBookings(kind, result) ->
      case model.page {
        RecurringBookingsPage(page_kind, day, _) if page_kind == kind -> {
          let overview = case result {
            Ok(slots) -> Loaded(slots)
            Error(_) -> Failed(LoadBookingsFailed)
          }
          #(
            Model(..model, page: RecurringBookingsPage(kind, day, overview)),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }

    // Change the selected day. `None` (an unparseable option) is ignored so the
    // current day sticks.
    UserSelectedOverviewDay(maybe_day) ->
      case model.page, maybe_day {
        RecurringBookingsPage(kind, _, overview), Some(day) -> #(
          Model(..model, page: RecurringBookingsPage(kind, day, overview)),
          effect.none(),
        )
        _, _ -> #(model, effect.none())
      }

    // Manual refresh. Keep the current data on screen while the refetch runs so
    // the list doesn't blank out (matches the silent once-a-minute refresh).
    UserClickedRefreshOverview ->
      case model.page {
        RecurringBookingsPage(kind, _, _) -> #(
          model,
          fetch_recurring_bookings(kind),
        )
        _ -> #(model, effect.none())
      }

    // A card links into that slot's full per-activity bookings view.
    UserClickedSlot(activity_id) -> #(
      model,
      modem.push(
        api_prefix
          <> "/activities/"
          <> uuid.to_string(activity_id)
          <> "/bookings",
        None,
        None,
      ),
    )

    // Once-a-minute tick: silently refetch the open overview; a no-op on every
    // other page.
    TimerTicked ->
      case model.page {
        RecurringBookingsPage(kind, _, _) -> #(
          model,
          fetch_recurring_bookings(kind),
        )
        _ -> #(model, effect.none())
      }

    UserClickedRetryLoad ->
      case model.page {
        ActivitiesListPage(filters, _) -> {
          let key = window_key_for(model, tab_source(filters.tab))
          #(set_window_remote(model, key, Loading), fetch_window(model, key))
        }
        _ -> #(model, effect.none())
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
            windows: dict.delete(model.windows, favourites_key()),
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
                False, Some(_) ->
                  case booking_cap_for(model, id, BookingNew) {
                    // No spots left — the Book button is disabled, so ignore.
                    Some(0) -> #(model, effect.none())
                    cap -> #(
                      Model(
                        ..model,
                        page: ActivityDetailPage(
                          id,
                          BookingOpen(
                            new_booking_form(model.translator, cap),
                            None,
                            BookingNew,
                          ),
                        ),
                      ),
                      effect.none(),
                    )
                  }
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
                    booking_form_from(
                      booking,
                      model.translator,
                      booking_cap_for(model, id, BookingEdit(booking.id)),
                    ),
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
        Model(
          ..model,
          statuses:,
          page:,
          windows: dict.delete(model.windows, favourites_key()),
        ),
        fetch_activity_spots(booking.activity_id),
      )
    }

    ApiCreatedBooking(Error(err)) ->
      case model.page {
        ActivityDetailPage(id, BookingSubmitting(mode)) -> {
          let app_error = booking_error(err, CreateBookingFailed)
          #(
            Model(
              ..model,
              page: ActivityDetailPage(
                id,
                BookingOpen(
                  new_booking_form(
                    model.translator,
                    booking_cap_for(model, id, mode),
                  ),
                  Some(app_error),
                  mode,
                ),
              ),
            ),
            capacity_refresh(app_error, id),
          )
        }
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

    ApiUpdatedBooking(Error(err)) ->
      case model.page {
        ActivityDetailPage(id, BookingSubmitting(mode)) -> {
          let app_error = booking_error(err, UpdateBookingFailed)
          #(
            Model(
              ..model,
              page: ActivityDetailPage(
                id,
                BookingOpen(
                  new_booking_form(
                    model.translator,
                    booking_cap_for(model, id, mode),
                  ),
                  Some(app_error),
                  mode,
                ),
              ),
            ),
            capacity_refresh(app_error, id),
          )
        }
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

    // Land the fetched bookings only if their activity is still the open
    // bookings page — a response for a page we've navigated away from is stale.
    ApiReturnedBookings(id, result) ->
      case model.page {
        ActivityBookingsPage(page_id, _) if page_id == id -> {
          let bookings = case result {
            Ok(bookings) -> Loaded(bookings)
            Error(_) -> Failed(LoadBookingsFailed)
          }
          #(
            Model(..model, page: ActivityBookingsPage(id, bookings)),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }
  }
}

fn update_filters(
  model: Model,
  f: fn(ListFilters) -> ListFilters,
) -> #(Model, Effect(Msg)) {
  case model.page {
    ActivitiesListPage(filters, mode) -> #(
      Model(..model, page: ActivitiesListPage(f(filters), mode)),
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

/// Whether this fetch should ask the server to include called-off activities.
/// Managers fetch the superset (the view filters call-offs out of browse tabs
/// itself, and shows them in the manage list); the favourited endpoint always
/// includes call-offs and ignores the parameter, so it never needs it.
fn source_include_call_offs(model: Model, source: ActivityListSource) -> Bool {
  case source {
    SourceFavourites -> False
    SourceActivities | SourceBeachBus | SourceClimbingWall ->
      has_role(model, ManageActivities)
  }
}

/// The request URL for a window: the source path plus the `?include_call_offs=`
/// and `?day=` params that make up its fetch identity. Favourites carries
/// neither (day is `None`, call-offs always included server-side).
fn window_url(key: WindowKey) -> String {
  let #(source, day, include_call_offs) = key
  let path = api_prefix <> list_source_path(source)
  let params =
    []
    |> prepend_if(include_call_offs, "include_call_offs=true")
    |> prepend_if_some(day, fn(d) { "day=" <> date_to_iso(d) })
  case params {
    [] -> path
    _ -> path <> "?" <> string.join(params, "&")
  }
}

fn prepend_if(list: List(a), condition: Bool, value: a) -> List(a) {
  case condition {
    True -> [value, ..list]
    False -> list
  }
}

fn prepend_if_some(
  list: List(a),
  maybe: Option(b),
  to_value: fn(b) -> a,
) -> List(a) {
  case maybe {
    Some(value) -> [to_value(value), ..list]
    None -> list
  }
}

fn set_if_none_match(
  req: request.Request(String),
  etag: Option(String),
) -> request.Request(String) {
  case etag {
    Some(tag) -> request.set_header(req, "if-none-match", tag)
    None -> req
  }
}

/// Conditionally fetch a window. Sends `If-None-Match` only when we already have
/// a loaded window for this exact key — so a `304` can only ever tell us to keep
/// data we're already showing, and a first/failed load always fetches
/// unconditionally. `rsvp.send` (needed to set the header) loses the convenience
/// helpers' relative-URL resolution, so we resolve against the iframe base
/// ourselves; that only works in the browser, which is the only place fetches run.
fn fetch_window(model: Model, key: WindowKey) -> Effect(Msg) {
  let etag = case window_remote(model, key) {
    Loaded(_) -> dict.get(model.etags, key) |> option.from_result
    NotAsked | Loading | Failed(_) -> None
  }
  case rsvp.parse_relative_uri(window_url(key)) {
    Error(_) -> effect.none()
    Ok(uri) ->
      case request.from_uri(uri) {
        Error(_) -> effect.none()
        Ok(req) ->
          req
          |> request.set_method(http.Get)
          |> set_if_none_match(etag)
          |> rsvp.send(activity_window_handler(key))
      }
  }
}

/// Interprets the raw HTTP response into a `WindowResult` (see its docs): `304`
/// → unchanged, `2xx` + decodable body → loaded with the new ETag, anything
/// else → failed.
fn activity_window_handler(key: WindowKey) -> rsvp.Handler(Msg) {
  rsvp.expect_any_response(fn(result) {
    let outcome = case result {
      Ok(resp) ->
        case resp.status {
          304 -> WindowUnchanged
          status if status >= 200 && status < 300 ->
            case json.parse(resp.body, model.activity_summaries_decoder()) {
              Ok(summaries) ->
                WindowLoaded(
                  summaries,
                  response.get_header(resp, "etag") |> option.from_result,
                )
              Error(_) -> WindowFailed
            }
          _ -> WindowFailed
        }
      Error(_) -> WindowFailed
    }
    ApiReturnedActivityWindow(key, outcome)
  })
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

/// Decode `{ "roles": [...] }`, keeping only roles the client models.
fn me_decoder() -> decode.Decoder(List(Role)) {
  use raw <- decode.field("roles", decode.list(decode.string))
  decode.success(list.filter_map(raw, role_from_string))
}

fn fetch_me() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/me",
    rsvp.expect_json(me_decoder(), ApiReturnedMe),
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

fn fetch_bookings(activity_id: Uuid) -> Effect(Msg) {
  rsvp.get(
    api_prefix
      <> "/api/activities/"
      <> uuid.to_string(activity_id)
      <> "/bookings",
    rsvp.expect_json(model.bookings_decoder(), fn(result) {
      ApiReturnedBookings(activity_id, result)
    }),
  )
}

/// The booking-overview endpoint path for a recurring kind. Not yet wired (see
/// `fetch_recurring_bookings`, which serves mock data) — kept here as the
/// single place the real URLs live for when the backend endpoint exists.
fn recurring_bookings_path(kind: RecurringKind) -> String {
  case kind {
    BeachBus -> "/api/beach-bus-bookings"
    ClimbingWall -> "/api/climbing-wall-bookings"
  }
}

// MOCK: the booking-overview aggregate endpoints don't exist server-side yet,
// so this returns hardcoded slots dated *today* to make the UI demoable. Swap
// the body for the real request once the backend ships the endpoint:
//
//   fn fetch_recurring_bookings(kind: RecurringKind) -> Effect(Msg) {
//     rsvp.get(
//       api_prefix <> recurring_bookings_path(kind),
//       rsvp.expect_json(model.booking_slots_decoder(), fn(result) {
//         ApiReturnedRecurringBookings(kind, result)
//       }),
//     )
//   }
fn fetch_recurring_bookings(kind: RecurringKind) -> Effect(Msg) {
  let _ = recurring_bookings_path
  effect.from(fn(dispatch) {
    dispatch(ApiReturnedRecurringBookings(kind, Ok(mock_slots(kind))))
  })
}

/// Today's date in the local time zone — the overview's default selected day.
fn today() -> calendar.Date {
  date_of(timestamp.system_time())
}

/// A local-time timestamp at `date` and the given clock time. Used to build the
/// mock slots; harmless helper otherwise.
fn at(date: calendar.Date, hours: Int, minutes: Int) -> Timestamp {
  timestamp.from_calendar(
    date,
    calendar.TimeOfDay(hours, minutes, 0, 0),
    calendar.local_offset(),
  )
}

/// MOCK slot data mirroring the design: a few slots today (one full, one busy,
/// one quiet) plus one tomorrow so the day dropdown has more than one option.
/// Climbing-wall slots use a smaller cap so the two pages look distinct.
fn mock_slots(kind: RecurringKind) -> List(BookingSlot) {
  let d = today()
  let tomorrow =
    date_of(timestamp.add(timestamp.system_time(), duration.hours(24)))
  let group = fn(id, name, count) {
    model.GroupCount(group_id: Some(id), group_name: Some(name), count:)
  }
  case kind {
    BeachBus -> [
      model.BookingSlot(
        uid("0198a000-0000-7000-8000-000000000001"),
        at(d, 10, 20),
        at(d, 10, 40),
        Some(45),
        43,
        [
          group(1, "Abbekås", 3),
          group(2, "Blentarps Scoutkår", 8),
          group(3, "Ölagets Scoutkår", 32),
        ],
      ),
      model.BookingSlot(
        uid("0198a000-0000-7000-8000-000000000002"),
        at(d, 10, 40),
        at(d, 11, 0),
        Some(45),
        45,
        [
          group(1, "Abbekås", 3),
          group(2, "Blentarps Scoutkår", 10),
          group(3, "Ölagets Scoutkår", 32),
        ],
      ),
      model.BookingSlot(
        uid("0198a000-0000-7000-8000-000000000003"),
        at(d, 11, 0),
        at(d, 11, 20),
        Some(45),
        12,
        [group(4, "Gärds Härads Scoutkår", 12)],
      ),
      model.BookingSlot(
        uid("0198a000-0000-7000-8000-000000000004"),
        at(tomorrow, 10, 20),
        at(tomorrow, 10, 40),
        Some(45),
        5,
        [group(1, "Abbekås", 5)],
      ),
    ]
    ClimbingWall -> [
      model.BookingSlot(
        uid("0198b000-0000-7000-8000-000000000001"),
        at(d, 9, 0),
        at(d, 9, 30),
        Some(12),
        12,
        [group(2, "Blentarps Scoutkår", 4), group(3, "Ölagets Scoutkår", 8)],
      ),
      model.BookingSlot(
        uid("0198b000-0000-7000-8000-000000000002"),
        at(d, 9, 30),
        at(d, 10, 0),
        Some(12),
        6,
        [group(1, "Abbekås", 2), group(4, "Gärds Härads Scoutkår", 4)],
      ),
      model.BookingSlot(
        uid("0198b000-0000-7000-8000-000000000003"),
        at(tomorrow, 9, 0),
        at(tomorrow, 9, 30),
        Some(12),
        3,
        [group(3, "Ölagets Scoutkår", 3)],
      ),
    ]
  }
}

/// Parse a hardcoded UUID literal (the mock slot ids). Asserts on a malformed
/// literal — these are compile-time constants, so a bad one is a programming
/// error, mirroring the locale asserts in `translator_for`.
fn uid(s: String) -> Uuid {
  let assert Ok(id) = uuid.from_string(s)
  id
}

@external(javascript, "./client_ffi.mjs", "set_interval")
fn set_interval(ms: Int, callback: fn() -> Nil) -> Nil

/// Start the once-a-minute refresh tick. Fired once at startup; `TimerTicked`
/// only does work while an overview page is open, so it's cheap elsewhere.
fn start_refresh_timer() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    set_interval(60_000, fn() { dispatch(TimerTicked) })
  })
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
  location_id: Option(Uuid),
) -> Effect(Msg) {
  rsvp.post(
    api_prefix <> "/api/activities",
    activity_form_to_json(af, tags, target_groups, location_id),
    rsvp.expect_json(model.activity_decoder(), ApiCreatedActivity),
  )
}

fn update_activity(
  id: Uuid,
  af: ActivityForm,
  tags: List(Uuid),
  target_groups: List(TargetGroup),
  location_id: Option(Uuid),
) -> Effect(Msg) {
  rsvp.put(
    api_prefix <> "/api/activities/" <> uuid.to_string(id),
    activity_form_to_json(af, tags, target_groups, location_id),
    rsvp.expect_json(model.activity_decoder(), ApiUpdatedActivity),
  )
}

/// Calls off (cancels) an activity with a reason. The server keeps the activity
/// but hides it from browse lists for everyone except booked/favourited users.
fn cancel_activity(id: Uuid, reason: String) -> Effect(Msg) {
  rsvp.post(
    api_prefix <> "/api/activities/" <> uuid.to_string(id) <> "/cancel",
    json.object([#("reason", json.string(reason))]),
    rsvp.expect_json(model.activity_decoder(), ApiCancelledActivity),
  )
}

fn fetch_activity_tags() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/activity-tags",
    rsvp.expect_json(model.activity_tags_decoder(), ApiReturnedActivityTags),
  )
}

fn fetch_locations() -> Effect(Msg) {
  rsvp.get(
    api_prefix <> "/api/locations",
    rsvp.expect_json(model.locations_decoder(), ApiReturnedLocations),
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
  location_id: Option(Uuid),
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
    #(
      "location_id",
      json.nullable(location_id, fn(id) { json.string(uuid.to_string(id)) }),
    ),
  ])
}

// ROUTING ---------------------------------------------------------------------

pub fn uri_to_page(
  uri: Uri,
  details: Dict(Uuid, RemoteData(ActivityDetail)),
) -> #(Page, Effect(Msg)) {
  case uri.path_segments(uri.path) |> list.drop(2) {
    ["activities"] | [] -> #(
      ActivitiesListPage(default_filters(), BrowseList),
      effect.none(),
    )
    ["activities", "new"] -> #(
      ActivityNewPage(activity_form(), None, [], []),
      effect.none(),
    )
    // The management copy of the activities list. Cards link to the edit view;
    // the menu item is only surfaced to managers (server-gated in app-config),
    // and edits are enforced server-side regardless of who reaches this route.
    ["activities", "manage"] -> #(
      ActivitiesListPage(default_filters(), ManageList),
      effect.none(),
    )
    // The Badbuss / Klättervägg booking-overview pages. Each loads its kind's
    // slots and defaults the day filter to today; the timer + manual refresh
    // refetch from here on.
    ["beach-bus"] -> #(
      RecurringBookingsPage(BeachBus, today(), Loading),
      fetch_recurring_bookings(BeachBus),
    )
    ["climbing-wall"] -> #(
      RecurringBookingsPage(ClimbingWall, today(), Loading),
      fetch_recurring_bookings(ClimbingWall),
    )
    ["activities", id_str, "bookings"] ->
      case uuid.from_string(id_str) {
        Ok(id) -> {
          // Reuse the cached activity for the header if present; otherwise fetch
          // it lazily. Spots and bookings are always refetched — both are
          // volatile and this is a management view of the live state.
          let activity_effect = case dict.get(details, id) {
            Ok(Loaded(_)) -> effect.none()
            _ -> fetch_activity(id)
          }
          #(
            ActivityBookingsPage(id, Loading),
            effect.batch([
              activity_effect,
              fetch_activity_spots(id),
              fetch_bookings(id),
            ]),
          )
        }
        Error(_) -> #(NotFoundPage, effect.none())
      }
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
    ["activities", id_str, "edit"] ->
      case uuid.from_string(id_str) {
        // Always fetch the activity fresh before editing, so the form reflects
        // the latest server state; `ApiReturnedActivity` seeds the form on reply.
        Ok(id) -> #(ActivityEditPage(id, EditLoading), fetch_activity(id))
        Error(_) -> #(NotFoundPage, effect.none())
      }
    _ -> #(NotFoundPage, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.page {
    ActivitiesListPage(filters, mode) ->
      view_activities_list(
        model.translator,
        tab_summaries(model, filters, mode),
        model.statuses,
        model.spots,
        filters,
        model.activity_tags,
        mode,
        model.today,
        model.browse_day_filter,
        model.favourites_day_filter,
      )
    ActivityNewPage(form, submit_error, tags, target_groups) ->
      view_activity_form(
        model.translator,
        form,
        submit_error,
        tags,
        target_groups,
        model.edit_ui,
        model.activity_tags,
        model.locations,
        CreateActivity,
      )
    ActivityDetailPage(id, booking) ->
      view_activity_detail(
        model.translator,
        detail_of(model, id),
        status_of(model.statuses, id),
        dict.get(model.spots, id) |> option.from_result,
        booking,
        model.activity_tags,
        can_view_bookings(model),
      )
    ActivityBookingsPage(id, bookings) ->
      view_activity_bookings(
        model.translator,
        detail_of(model, id),
        dict.get(model.spots, id) |> option.from_result,
        bookings,
      )
    RecurringBookingsPage(kind, selected_day, overview) ->
      view_recurring_bookings(model.translator, kind, selected_day, overview)
    ActivityEditPage(_, EditLoading) ->
      html.div([attribute.class("flex justify-center py-8")], [
        component.scout_loader(g18n.translate(
          model.translator,
          "activity.loading",
        )),
      ])
    ActivityEditPage(
      _,
      EditReady(form:, submit_error:, tags:, target_groups:, ..),
    ) ->
      view_activity_form(
        model.translator,
        form,
        submit_error,
        tags,
        target_groups,
        model.edit_ui,
        model.activity_tags,
        model.locations,
        EditActivity,
      )
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
  mode: ListMode,
  today: calendar.Date,
  browse_day: Option(calendar.Date),
  favourites_day: Option(calendar.Date),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  // Favourites spans all days server-side; its optional day pick narrows the
  // list client-side. Browse tabs are day-windowed server-side, so no
  // client-side day filter applies to them.
  let client_day = case filters.tab {
    TabFavourites -> favourites_day
    _ -> None
  }

  html.div([attribute.class("flex flex-col")], [
    view_list_top_bar(
      translator,
      filters,
      mode,
      today,
      browse_day,
      favourites_day,
    ),
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
            mode,
            client_day,
          )
      },
    ]),
  ])
}

fn view_list_top_bar(
  translator: Translator,
  filters: ListFilters,
  mode: ListMode,
  today: calendar.Date,
  browse_day: Option(calendar.Date),
  favourites_day: Option(calendar.Date),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  // The day dropdown is a static list of the event dates. Favourites offers an
  // "all days" option and defaults to it; the browse tabs offer only single
  // days and default to today (clamped into the event range). The selection is
  // read from the Model's per-view day fields so it survives navigation.
  let show_any = filters.tab == TabFavourites
  let selected_day = case filters.tab {
    TabFavourites -> favourites_day
    _ -> Some(option.unwrap(browse_day, today))
  }
  let tab_labels =
    list.map(list_tabs_for(mode), fn(tab) { tab_label(translator, tab) })
  html.div(
    [
      attribute.class(
        "flex flex-col gap-2 bg-white border-b border-gray-200 p-3",
      ),
    ],
    [
      // The management list leads with a prominent create action; the browse
      // list has none.
      case mode {
        ManageList -> view_new_activity_button(translator)
        BrowseList -> element.none()
      },
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
      // Key the day select by its option set: `scout-select` consumes its own
      // `<option>` children, so reconciling them in place desyncs Lustre's DOM
      // when the set changes (the "all days" option appears/disappears crossing
      // the Favourites boundary). A key that flips with `show_any` makes Lustre
      // replace the whole element instead.
      keyed.div([attribute.class("flex items-center gap-2")], [
        #(
          "day-select-"
            <> case show_any {
            True -> "any"
            False -> "days"
          },
          view_day_select(translator, selected_day, show_any),
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

/// Primary call-to-action on the management list: start creating a new
/// activity. Navigates to the create form via `UserClickedNewActivity`; the
/// create flow itself is unchanged.
fn view_new_activity_button(translator: Translator) -> Element(Msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", "primary"),
      attribute.attribute("icon", icons.plus),
      attribute.attribute("icon-position", "before"),
      attribute.class("w-full"),
      event.on("scoutClick", decode.success(UserClickedNewActivity)),
    ],
    [element.text(g18n.translate(translator, "manage.new_activity"))],
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

/// The day dropdown. Options are the static event dates; `show_any` adds the
/// leading "all days" option (Favourites only). `selected` drives which option
/// is marked selected.
fn view_day_select(
  translator: Translator,
  selected: Option(calendar.Date),
  show_any: Bool,
) -> Element(Msg) {
  let any_value = "__any__"
  let selected_value = case selected {
    None -> any_value
    Some(date) -> date_to_iso(date)
  }
  let any_option = case show_any {
    True -> [
      html.option(
        [
          attribute.value(any_value),
          attribute.selected(selected_value == any_value),
        ],
        g18n.translate(translator, "list.day.any"),
      ),
    ]
    False -> []
  }
  let date_options =
    list.map(event_dates.event_days(), fn(date) {
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
    list.append(any_option, date_options),
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

/// The create/edit form's location picker: a searchable dropdown (combobox).
/// The text field filters locations by localized name; matches drop down in a
/// list below, and clicking one selects it (a leading "no location" entry
/// clears the choice). While open the field shows the live query; while closed
/// it shows the chosen location's name.
///
/// Options are selected on `mousedown` — which fires before the field's blur —
/// so the blur that closes the list never swallows the click.
fn view_location_picker(
  translator: Translator,
  locations: Dict(Uuid, Location),
  selected: Option(Uuid),
  query: String,
  open: Bool,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let name_of = fn(id) {
    case dict.get(locations, id) {
      Ok(l) -> localized(translator, l.name)
      Error(_) -> ""
    }
  }
  let matches =
    dict.values(locations)
    |> list.sort(fn(a, b) {
      string.compare(
        localized(translator, a.name),
        localized(translator, b.name),
      )
    })
    |> list.filter(fn(l) {
      case query |> string.trim |> string.lowercase {
        "" -> True
        needle ->
          string.contains(
            string.lowercase(localized(translator, l.name)),
            needle,
          )
      }
    })
  // Field text: the live query while searching, else the chosen location's name.
  let field_value = case open, selected {
    True, _ -> query
    False, Some(id) -> name_of(id)
    False, None -> ""
  }
  let option_button = fn(label: String, is_selected: Bool, msg: Msg) {
    let base =
      "w-full text-left px-3 py-2 text-body-sm cursor-pointer hover:bg-gray-100 "
    html.button(
      [
        attribute.type_("button"),
        attribute.class(case is_selected {
          True -> base <> "bg-gray-100 font-semibold"
          False -> base
        }),
        // mousedown (not click) so selection lands before the field's blur.
        event.on("mousedown", decode.success(msg)),
      ],
      [element.text(label)],
    )
  }
  html.div([attribute.class("flex flex-col gap-2")], [
    html.h4([attribute.class("text-body-sm font-semibold")], [
      element.text(t("edit.location")),
    ]),
    html.div([attribute.class("relative")], [
      // Clicking the field opens the list; typing filters it; blur closes it.
      html.div([event.on("click", decode.success(UserOpenedLocationDropdown))], [
        element.element(
          "scout-input",
          [
            attribute.attribute("type", "text"),
            attribute.attribute("placeholder", t("edit.location_search")),
            attribute.attribute("value", field_value),
            event.on_input(UserSearchedLocation),
            event.on("scoutBlur", decode.success(UserClosedLocationDropdown)),
          ],
          [],
        ),
      ]),
      case open {
        False -> element.none()
        True ->
          html.div(
            [
              attribute.class(
                "absolute left-0 right-0 z-10 mt-1 max-h-56 overflow-y-auto rounded-md border border-gray-300 bg-white shadow-lg",
              ),
            ],
            [
              option_button(
                t("edit.location_none"),
                selected == None,
                UserSelectedLocation(None),
              ),
              ..list.map(matches, fn(l) {
                option_button(
                  localized(translator, l.name),
                  selected == Some(l.id),
                  UserSelectedLocation(Some(l.id)),
                )
              })
            ],
          )
      },
    ]),
  ])
}

fn view_grouped_activities(
  translator: Translator,
  items: List(CardItem),
  filters: ListFilters,
  mode: ListMode,
  client_day: Option(calendar.Date),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let filtered =
    apply_filters(items, filters, client_day)
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
          view_section(translator, date, bucket, items, is_current, mode)
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
  mode: ListMode,
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
      list.map(items, fn(item) {
        view_activity_card(translator, date, item, mode)
      }),
    ),
  ])
}

fn view_activity_card(
  translator: Translator,
  section_date: calendar.Date,
  item: CardItem,
  mode: ListMode,
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
  // A called-off activity shows an "Inställd" chip in both lists — it's an
  // intrinsic property, not the viewer's booking state, and managers need to
  // see it on the management list. Otherwise the chip ("Bokad"/"Behöver bokas")
  // reflects the viewer's own booking state, which is irrelevant when managing,
  // so it shows only in browse.
  let status = case summary.cancellation {
    Some(_) ->
      component.StatusCancelled(g18n.translate(
        translator,
        "activity.called_off",
      ))
    None ->
      case mode {
        BrowseList -> card_status(translator, summary, item.status)
        ManageList -> component.StatusNone
      }
  }
  // Browse cards link to the detail page and carry a favourite heart; manage
  // cards link to the edit page and carry an edit pen. Everything else about
  // the card is identical, so the two lists share the whole view.
  let #(href, action) = case mode {
    BrowseList -> #(
      api_prefix <> "/activities/" <> id,
      component.FavouriteAction(
        favourited: is_favourited(item.status),
        on_toggle: UserToggledFavourite(summary.id),
      ),
    )
    ManageList -> #(
      api_prefix <> "/activities/" <> id <> "/edit",
      component.EditAction,
    )
  }
  component.activity_card(
    href,
    localized(translator, summary.title),
    status,
    action,
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

/// Localized validation error messages for the activity form (formal's built-in
/// messages are English only). Applied via `form.language` in the form view.
fn form_error_message(
  translator: Translator,
  error: form.FieldError,
) -> String {
  let t = fn(key) { g18n.translate(translator, key) }
  case error {
    form.MustBePresent -> t("form.error.required")
    form.MustBeInt -> t("form.error.int")
    form.MustBeDateTime -> t("form.error.datetime")
    _ -> t("form.error.invalid")
  }
}

/// After a failed submit, pick the language whose bilingual fields still have
/// errors so they're visible under the sv/en toggle. Stays on the current
/// language if it already has errors (or if neither language does).
fn language_needing_attention(
  form: Form(ActivityForm),
  current: EditLanguage,
) -> EditLanguage {
  let has = fn(name) { form.field_errors(form, name) != [] }
  let sv_err = has("title") || has("description")
  let en_err = has("title_en") || has("description_en")
  case current {
    EditSwedish ->
      case sv_err, en_err {
        False, True -> EditEnglish
        _, _ -> EditSwedish
      }
    EditEnglish ->
      case en_err, sv_err {
        False, True -> EditSwedish
        _, _ -> EditEnglish
      }
  }
}

/// Whether the shared activity form is creating a new activity or editing an
/// existing one. Create hides the "Ställ in" (call off) action and returns to
/// the management list on cancel; edit keeps call-off and returns to the detail
/// page.
pub type ActivityFormMode {
  CreateActivity
  EditActivity
}

/// Shared create/edit form. `/activities/new` (`CreateActivity`) and
/// `/activities/:id/edit` (`EditActivity`) render the same UI; they differ only
/// in the submit message, the action row, and the cancel destination.
fn view_activity_form(
  translator: Translator,
  form: Form(ActivityForm),
  submit_error: Option(AppError),
  selected_tags: List(Uuid),
  selected_target_groups: List(TargetGroup),
  edit_ui: EditUi,
  activity_tags: Dict(Uuid, ActivityTag),
  locations: Dict(Uuid, Location),
  mode: ActivityFormMode,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  // Localize validation errors — formal's built-in messages are English only.
  let form = form.language(form, form_error_message(translator, _))
  let submitted = fn(values) {
    let result = form |> form.add_values(values) |> form.run
    case mode {
      CreateActivity -> UserSubmittedCreateForm(result)
      EditActivity -> UserSubmittedEditForm(result)
    }
  }
  let sv_active = edit_ui.language == EditSwedish
  let lang_index = case edit_ui.language {
    EditSwedish -> 0
    EditEnglish -> 1
  }
  // Both language variants stay mounted so their (uncontrolled) values survive a
  // toggle and are all submitted; only the active one is shown. A failed submit
  // switches to whichever language has errors (see update), so a required field
  // in the other language is never stuck invisible behind the toggle.
  let hidden_unless = fn(active: Bool) {
    attribute.class(case active {
      True -> ""
      False -> "hidden"
    })
  }
  let field = fn(active: Bool, label: String, input_type: String, name: String) {
    html.div([hidden_unless(active)], [
      component.scout_form_field(form, label, input_type, name),
    ])
  }
  let area = fn(active: Bool, label: String, name: String) {
    html.div([hidden_unless(active)], [
      component.scout_textarea_field(form, label, name, 4),
    ])
  }
  html.div([attribute.class("flex flex-col")], [
    // Call-off confirmation modal — edit only (you can't call off an activity
    // that doesn't exist yet). Rendered outside the form so its confirm button
    // never submits.
    case mode {
      EditActivity -> view_call_off_drawer(translator, edit_ui)
      CreateActivity -> element.none()
    },
    html.div([attribute.class("flex flex-col gap-4 p-3")], [
      // Language toggle for the activity's bilingual fields.
      html.div([attribute.class("flex justify-end")], [
        component.scout_segmented_control(
          lang_index,
          [t("edit.lang_sv"), t("edit.lang_en")],
          fn(index) {
            case index {
              0 -> UserSelectedEditLanguage(EditSwedish)
              _ -> UserSelectedEditLanguage(EditEnglish)
            }
          },
          [],
        ),
      ]),
      case submit_error {
        Some(err) ->
          component.error_banner(t("error.heading"), t(app_error_key(err)))
        None -> element.none()
      },
      html.form([event.on_submit(submitted)], [
        component.scout_card([
          html.div([attribute.class("flex flex-col gap-2")], [
            field(sv_active, t("edit.name"), "text", "title"),
            field(!sv_active, t("edit.name"), "text", "title_en"),
            area(sv_active, t("edit.description"), "description"),
            area(!sv_active, t("edit.description"), "description_en"),
            component.scout_form_field(
              form,
              t("edit.max_attendees"),
              "number",
              "max_attendees",
            ),
            component.scout_form_field(
              form,
              t("edit.start_time"),
              "datetime-local",
              "start_time",
            ),
            component.scout_form_field(
              form,
              t("edit.end_time"),
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
                view_location_picker(
                  translator,
                  locations,
                  edit_ui.location_id,
                  edit_ui.location_query,
                  edit_ui.location_open,
                ),
                view_form_actions(translator, mode),
              ],
            )
          ]),
        ]),
      ]),
    ]),
  ])
}

/// The form's action row. Edit shows call off (ställ in) + cancel (avbryt) +
/// save (spara); create drops call-off (nothing to call off yet). Only "save"
/// submits the form (`type=submit`); the others are `type=button`.
fn view_form_actions(
  translator: Translator,
  mode: ActivityFormMode,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  let call_off = case mode {
    EditActivity -> [
      element.element(
        "scout-button",
        [
          attribute.attribute("variant", "danger"),
          attribute.attribute("type", "button"),
          event.on("scoutClick", decode.success(UserToggledCallOff)),
        ],
        [element.text(t("edit.call_off"))],
      ),
    ]
    CreateActivity -> []
  }
  html.div(
    [attribute.class("flex flex-wrap gap-2 pt-2")],
    list.flatten([
      call_off,
      [
        element.element(
          "scout-button",
          [
            attribute.attribute("variant", "outlined"),
            attribute.attribute("type", "button"),
            event.on("scoutClick", decode.success(UserClickedCancelEdit)),
          ],
          [element.text(t("edit.cancel"))],
        ),
        element.element(
          "scout-button",
          [
            attribute.attribute("variant", "primary"),
            attribute.attribute("type", "submit"),
          ],
          [element.text(t("edit.save"))],
        ),
      ],
    ]),
  )
}

/// The call-off confirmation modal: a drawer holding the reason input and a
/// danger "confirm" button. Opened by the "Ställ in" action; the exit button or
/// a confirm closes it. UI-only for now — the reason is captured in `edit_ui`
/// but not yet persisted.
fn view_call_off_drawer(
  translator: Translator,
  edit_ui: EditUi,
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  component.scout_drawer(
    edit_ui.cancel_open,
    t("edit.call_off_title"),
    UserToggledCallOff,
    [
      html.div([attribute.class("flex flex-col gap-4")], [
        component.scout_field(
          t("edit.reason"),
          element.element(
            "scout-input",
            [
              attribute.attribute("type", "text"),
              attribute.attribute("value", edit_ui.cancel_reason),
              event.on_input(UserEditedCallOffReason),
            ],
            [],
          ),
        ),
        component.scout_button_action(
          t("edit.confirm_call_off"),
          "danger",
          UserClickedConfirmCallOff,
        ),
      ]),
    ],
  )
}

fn view_activity_detail(
  translator: Translator,
  state: RemoteData(Activity),
  status: ActivityStatus,
  spots_booked: Option(Int),
  booking: BookingFormState,
  activity_tags: Dict(Uuid, ActivityTag),
  can_view_bookings: Bool,
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
        can_view_bookings,
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
  can_view_bookings: Bool,
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
      [
        view_booking_form_section(
          translator,
          booking,
          activity.max_attendees,
          spots_booked,
          status,
        ),
      ],
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
          // Header row: title takes the full width with the favourite toggle
          // pinned top-right beside it.
          [attribute.class("flex items-start gap-3")],
          [
            html.h1(
              [
                attribute.class(
                  "flex-1 pt-1 min-w-0 text-heading-xs hyphens-auto break-words text-balance",
                ),
              ],
              [element.text(localized(translator, activity.title))],
            ),
            heart_btn,
          ],
        ),
        // Called-off notice: shown to the booked/favourited users who can still
        // see the activity, with the reason the manager gave.
        case activity.cancellation {
          Some(reason) ->
            component.warning_banner(
              g18n.translate(translator, "activity.called_off"),
              reason,
            )
          None -> element.none()
        },
        html.div(
          // Action bar under the title: booking actions followed by the
          // management-only "Visa bokningar" action, wrapping to a new row
          // when they fill the width, with spots-remaining as a caption
          // beneath.
          [attribute.class("flex flex-col gap-1")],
          [
            html.div([attribute.class("flex flex-wrap items-center gap-2")], {
              let #(primary, secondary) =
                view_detail_actions(
                  translator,
                  activity,
                  is_booked(status),
                  booking,
                  spots_booked,
                )
              [
                primary,
                secondary,
                // View this activity's bookings. Shown only to users who may
                // read bookings, and only for bookable activities (others
                // can't have bookings).
                case
                  can_view_bookings && option.is_some(activity.max_attendees)
                {
                  True ->
                    component.scout_button_action(
                      g18n.translate(translator, "activity.show_bookings"),
                      "outlined",
                      UserClickedShowBookings,
                    )
                  False -> element.none()
                },
              ]
            }),
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
                      "flex gap-1 items-center text-body-sm text-gray-500",
                    ),
                  ],
                  [
                    component.icon(icons.users, "size-4"),
                    html.p([], [element.text(text)]),
                  ],
                )
              None -> element.none()
            },
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
  spots_booked: Option(Int),
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
    // the row behind it. A called-off activity drops "Ändra bokning" (no
    // changes to a cancelled activity) but keeps "Avboka" so booked users can
    // still remove themselves.
    True, _ -> #(
      case activity.cancellation {
        Some(_) -> element.none()
        None ->
          component.scout_button_action(
            g18n.translate(translator, "booking.change"),
            "primary",
            UserClickedChangeBooking,
          )
      },
      component.scout_button_action(
        g18n.translate(translator, "booking.unbook"),
        "danger",
        UserClickedUnbook,
      ),
    )

    // Not booked: the "Boka" button if the activity has capacity, shown as a
    // disabled "Full" button when no spots remain (known count only). A
    // called-off activity offers no booking action at all.
    False, _ ->
      case activity.cancellation {
        Some(_) -> #(element.none(), element.none())
        None ->
          case activity.max_attendees {
            Some(_) ->
              case model.spots_remaining(activity.max_attendees, spots_booked) {
                model.Remaining(0) -> #(
                  component.scout_button_disabled(
                    g18n.translate(translator, "activity.full"),
                    "primary",
                  ),
                  element.none(),
                )
                _ -> #(
                  component.scout_button_action(
                    g18n.translate(translator, "activity.book"),
                    "primary",
                    UserClickedBook,
                  ),
                  element.none(),
                )
              }
            None -> #(element.none(), element.none())
          }
      }
  }
}

fn view_booking_form_section(
  translator: Translator,
  booking: BookingFormState,
  max_attendees: Option(Int),
  spots_booked: Option(Int),
  status: ActivityStatus,
) -> Element(Msg) {
  case booking {
    BookingClosed -> element.none()
    UnbookConfirming(_) -> element.none()
    UnbookSubmitting(_) -> element.none()
    BookingSubmitting(_) ->
      html.div([attribute.class("flex justify-center py-4")], [
        component.scout_loader(g18n.translate(translator, "booking.submitting")),
      ])
    BookingOpen(form, submit_error, mode) -> {
      let max_participants =
        cap_for_mode(max_attendees, spots_booked, status, mode)
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
          component.scout_form_number_field(
            form,
            g18n.translate(translator, "booking.participant_count"),
            "participant_count",
            1,
            max_participants,
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

/// The management-only bookings list for one activity: a header echoing the
/// activity (title, time, spots filled) above a card per booking. The header
/// reads from the shared caches via `activity_state`; `bookings` is the
/// per-route fetch.
fn view_activity_bookings(
  translator: Translator,
  activity_state: RemoteData(Activity),
  spots_booked: Option(Int),
  bookings: RemoteData(List(Booking)),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  html.div([attribute.class("flex flex-col p-3 gap-4")], [
    view_bookings_header(translator, activity_state, spots_booked),
    html.div([attribute.class("flex flex-col gap-3")], [
      html.h2([attribute.class("text-body-l font-semibold")], [
        element.text(t("bookings.heading")),
      ]),
      case bookings {
        NotAsked | Loading ->
          html.div([attribute.class("flex justify-center py-6")], [
            component.scout_loader(t("bookings.loading")),
          ])
        Failed(err) ->
          component.error_banner(t("error.heading"), t(app_error_key(err)))
        Loaded([]) ->
          html.p([attribute.class("py-6 text-center text-gray-500")], [
            element.text(t("bookings.empty")),
          ])
        Loaded(items) ->
          keyed.div(
            [attribute.class("flex flex-col gap-3")],
            list.map(items, fn(booking) {
              #(
                uuid.to_string(booking.id),
                view_booking_card(translator, booking),
              )
            }),
          )
      },
    ]),
  ])
}

// RECURRING BOOKINGS OVERVIEW -------------------------------------------------

/// The heading text for a kind's overview (also the app-bar title).
fn recurring_title(translator: Translator, kind: RecurringKind) -> String {
  case kind {
    BeachBus -> g18n.translate(translator, "app_bar.beach_bus_bookings")
    ClimbingWall -> g18n.translate(translator, "app_bar.climbing_wall_bookings")
  }
}

/// The Badbuss / Klättervägg booking overview: a heading with a manual-refresh
/// button, a day dropdown, then one card per slot for the selected day — each
/// showing the slot time, the X / Y filled count (red "Fullbokat!" when full),
/// and the per-kår participant tally, sorted by kår name. The page also
/// auto-refreshes once a minute; each card drills into that slot's full
/// bookings view.
fn view_recurring_bookings(
  translator: Translator,
  kind: RecurringKind,
  selected_day: calendar.Date,
  overview: RemoteData(List(BookingSlot)),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  html.div([attribute.class("flex flex-col p-3 gap-4")], [
    html.div([attribute.class("flex items-center justify-between gap-2")], [
      html.h1([attribute.class("text-heading-xs")], [
        element.text(recurring_title(translator, kind)),
      ]),
      html.button(
        [
          attribute.class(
            "shrink-0 cursor-pointer text-gray-600 hover:text-gray-900",
          ),
          attribute.attribute("type", "button"),
          attribute.attribute("aria-label", t("overview.refresh")),
          event.on_click(UserClickedRefreshOverview),
        ],
        [component.icon(icons.refresh, "size-6")],
      ),
    ]),
    // The day dropdown appears as soon as data is loaded, so the user can switch
    // days even when the current one has no slots.
    case overview {
      Loaded(slots) -> view_overview_day_select(translator, selected_day, slots)
      NotAsked | Loading | Failed(_) -> element.none()
    },
    case overview {
      NotAsked | Loading ->
        html.div([attribute.class("flex justify-center py-6")], [
          component.scout_loader(t("bookings.loading")),
        ])
      Failed(err) ->
        component.error_banner(t("error.heading"), t(app_error_key(err)))
      Loaded(slots) -> {
        let day_slots =
          slots
          |> list.filter(fn(s) { date_of(s.start_time) == selected_day })
          |> list.sort(fn(a, b) {
            timestamp.compare(a.start_time, b.start_time)
          })
        case day_slots {
          [] ->
            html.p([attribute.class("py-6 text-center text-gray-500")], [
              element.text(t("overview.empty")),
            ])
          _ ->
            keyed.div(
              [attribute.class("flex flex-col gap-4")],
              list.map(day_slots, fn(slot) {
                #(
                  uuid.to_string(slot.activity_id),
                  view_slot_card(translator, slot),
                )
              }),
            )
        }
      }
    },
  ])
}

/// The day dropdown for the overview. Options are every day that has slots, plus
/// the selected day (so today still appears when it has none). Keyed by its date
/// set because `scout-select` owns its `<option>` children (see `view_day_select`).
fn view_overview_day_select(
  translator: Translator,
  selected: calendar.Date,
  slots: List(BookingSlot),
) -> Element(Msg) {
  let selected_value = date_to_iso(selected)
  let dates =
    [selected, ..list.map(slots, fn(s) { date_of(s.start_time) })]
    |> list.unique
    |> list.sort(calendar.naive_date_compare)
  let options =
    list.map(dates, fn(date) {
      let value = date_to_iso(date)
      html.option(
        [attribute.value(value), attribute.selected(value == selected_value)],
        g18n.format_date(translator, date, g18n.Custom("EEEE d/M")),
      )
    })
  keyed.div([attribute.class("flex")], [
    #(
      "overview-day-" <> string.join(list.map(dates, date_to_iso), ","),
      element.element(
        "scout-select",
        [
          attribute.class("min-w-0"),
          attribute.attribute("name", "day"),
          attribute.attribute("value", selected_value),
          event.on("scoutInputChange", {
            use value <- decode.subfield(["detail", "value"], decode.string)
            decode.success(UserSelectedOverviewDay(parse_date_iso(value)))
          }),
        ],
        options,
      ),
    ),
  ])
}

/// One slot rendered as a tappable card: a time + "X / Y" (or red "Fullbokat!")
/// header row above a card listing each kår and its participant count.
fn view_slot_card(translator: Translator, slot: BookingSlot) -> Element(Msg) {
  let #(_, start_time) =
    timestamp.to_calendar(slot.start_time, calendar.local_offset())
  let full = case slot.max_attendees {
    Some(max) -> slot.total_booked >= max
    None -> False
  }
  let count_label = case slot.max_attendees {
    Some(max) -> int.to_string(slot.total_booked) <> " / " <> int.to_string(max)
    None -> int.to_string(slot.total_booked)
  }
  let groups =
    list.sort(slot.groups, fn(a, b) {
      string.compare(
        group_display_name(translator, a),
        group_display_name(translator, b),
      )
    })
  html.div(
    [
      attribute.class("flex flex-col gap-1 cursor-pointer"),
      event.on_click(UserClickedSlot(slot.activity_id)),
    ],
    [
      html.div(
        [attribute.class("flex items-baseline justify-between gap-2 px-1")],
        [
          html.span([attribute.class("text-body-l font-semibold")], [
            element.text(format_clock(translator, start_time)),
          ]),
          case full {
            True ->
              html.span(
                [attribute.class("text-body-l font-semibold text-red-600")],
                [
                  element.text(
                    g18n.translate(translator, "overview.fully_booked")
                    <> " "
                    <> count_label,
                  ),
                ],
              )
            False ->
              html.span([attribute.class("text-body-l text-gray-700")], [
                element.text(count_label),
              ])
          },
        ],
      ),
      html.div([attribute.class("shadow-sm rounded-[var(--spacing-6)]")], [
        component.scout_card([
          html.div(
            [attribute.class("flex flex-col gap-1")],
            list.map(groups, fn(group) {
              html.div(
                [attribute.class("flex items-baseline justify-between gap-3")],
                [
                  html.span([attribute.class("text-body-l break-words")], [
                    element.text(group_display_name(translator, group)),
                  ]),
                  html.span(
                    [attribute.class("text-body-l font-semibold shrink-0")],
                    [element.text(int.to_string(group.count))],
                  ),
                ],
              )
            }),
          ),
        ]),
      ]),
    ],
  )
}

/// A kår's display name, falling back to the "unknown group" label for bookings
/// made without a kår.
fn group_display_name(translator: Translator, group: GroupCount) -> String {
  case group.group_name {
    Some(name) -> name
    None -> g18n.translate(translator, "bookings.unknown_group")
  }
}

/// The activity summary shown atop the bookings list. Mirrors the loading/error
/// states of the shared activity cache so the header doesn't flash "not found".
fn view_bookings_header(
  translator: Translator,
  activity_state: RemoteData(Activity),
  spots_booked: Option(Int),
) -> Element(Msg) {
  let t = fn(key) { g18n.translate(translator, key) }
  case activity_state {
    NotAsked | Loading ->
      html.div([attribute.class("flex justify-center py-6")], [
        component.scout_loader(t("activity.loading")),
      ])
    Failed(err) ->
      component.error_banner(t("error.heading"), t(app_error_key(err)))
    Loaded(activity) ->
      html.div(
        [attribute.class("flex flex-col gap-2 border-b border-gray-200 pb-4")],
        [
          html.h1(
            [
              attribute.class(
                "text-heading-xs hyphens-auto break-words text-balance",
              ),
            ],
            [element.text(localized(translator, activity.title))],
          ),
          html.div(
            [attribute.class("flex flex-col gap-1 text-body-sm text-gray-600")],
            [
              html.div([attribute.class("flex items-start gap-1")], [
                component.icon(icons.clock, "size-4 shrink-0 mt-0.5"),
                view_time_interval(
                  translator,
                  activity.start_time,
                  activity.end_time,
                ),
              ]),
              case
                spots_filled_text(
                  translator,
                  activity.max_attendees,
                  spots_booked,
                )
              {
                Some(text) ->
                  html.div([attribute.class("flex items-center gap-1")], [
                    component.icon(icons.users, "size-4 shrink-0"),
                    html.span([], [element.text(text)]),
                  ])
                None -> element.none()
              },
            ],
          ),
        ],
      )
  }
}

/// One booking rendered as a card: the booker group in bold, then the
/// free-text group (when a scout group name is also present), participant
/// count, responsible leader, and a tappable phone link.
fn view_booking_card(translator: Translator, booking: Booking) -> Element(Msg) {
  // Prefer the scout group name from the booker's token; fall back to the
  // free-text group, then to a placeholder when neither is present (the
  // free-text field is optional, so both can be empty).
  let group_title = case booking.booker_group_name, booking.group_free_text {
    Some(name), _ -> name
    None, "" -> g18n.translate(translator, "bookings.unknown_group")
    None, free_text -> free_text
  }
  // Match the activity-list cards' resting elevation + radius so both lists
  // read as one system. scout-card supplies the white padded surface; the
  // shadow lives on the wrapper (as in `component.activity_card`) to survive
  // the shadow-DOM boundary. No hover/focus states — a booking isn't a link.
  html.div(
    [
      attribute.class("shadow-sm rounded-[var(--spacing-6)]"),
    ],
    [
      component.scout_card([
        html.div([attribute.class("flex flex-col gap-1")], [
          html.h3(
            [
              attribute.class(
                "text-body-l font-semibold leading-tight break-words",
              ),
            ],
            [element.text(group_title)],
          ),
          // Show the free-text group as a secondary line only when it isn't already
          // the title (i.e. a token group name is present) and it's non-empty.
          case booking.booker_group_name, booking.group_free_text {
            Some(_), free_text if free_text != "" ->
              html.p([attribute.class("text-body-sm text-gray-700")], [
                element.text(free_text),
              ])
            _, _ -> element.none()
          },
          html.p([attribute.class("text-body-sm text-gray-700")], [
            element.text(g18n.translate_plural(
              translator,
              "bookings.participants",
              booking.participant_count,
            )),
          ]),
          html.p([attribute.class("text-body-sm text-gray-700")], [
            element.text(booking.responsible_name),
          ]),
          html.a(
            [
              attribute.href("tel:" <> booking.phone_number),
              attribute.class("text-body-sm text-blue-700 no-underline"),
            ],
            [element.text(booking.phone_number)],
          ),
        ]),
      ]),
    ],
  )
}

/// The "X / Y platser fyllda" caption for the bookings header. `None` for an
/// uncapped activity or when the booked count isn't in hand.
fn spots_filled_text(
  translator: Translator,
  max_attendees: Option(Int),
  spots_booked: Option(Int),
) -> Option(String) {
  case max_attendees, spots_booked {
    Some(max), Some(booked) ->
      Some(g18n.translate_with_params(
        translator,
        "bookings.spots_filled",
        g18n.new_format_params()
          |> g18n.add_param("booked", int.to_string(booked))
          |> g18n.add_param("max", int.to_string(max)),
      ))
    _, _ -> None
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

pub fn apply_filters(
  items: List(CardItem),
  f: ListFilters,
  client_day: Option(calendar.Date),
) -> List(CardItem) {
  let needle = string.lowercase(string.trim(f.search))
  use item <- list.filter(items)
  let summary = item.summary
  let title_match = case needle {
    "" -> True
    _ ->
      string.contains(string.lowercase(summary.title.sv), needle)
      || string.contains(string.lowercase(summary.title.en), needle)
  }
  // Browse tabs are day-windowed server-side, so the response already contains
  // only the selected day and the caller passes `None`. Favourites spans all
  // days, so its optional day pick is passed in and narrows the list here.
  let day_match = case client_day {
    Some(date) -> date_of(summary.start_time) == date
    None -> True
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
