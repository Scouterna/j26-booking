import client
import gleam/dict
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/calendar
import gleam/time/timestamp
import gleam/uri
import gleeunit
import rsvp
import shared/model
import youid/uuid.{type Uuid}

pub fn main() -> Nil {
  gleeunit.main()
}

// FIXTURES --------------------------------------------------------------------

fn uid(s: String) -> Uuid {
  let assert Ok(id) = uuid.from_string(s)
  id
}

fn id_a() -> Uuid {
  uid("00000000-0000-0000-0000-00000000000a")
}

fn id_b() -> Uuid {
  uid("00000000-0000-0000-0000-00000000000b")
}

fn id_c() -> Uuid {
  uid("00000000-0000-0000-0000-00000000000c")
}

fn a_summary(
  id: Uuid,
  title: String,
  max: Option(Int),
) -> model.ActivitySummary {
  model.ActivitySummary(
    id:,
    title: model.BilingualString(sv: title, en: title),
    max_attendees: max,
    start_time: timestamp.from_unix_seconds(1_750_000_000),
    end_time: timestamp.from_unix_seconds(1_750_003_600),
    location_name: None,
    tags: [],
    target_groups: [],
    cancellation: None,
  )
}

fn an_activity(id: Uuid, max: Option(Int)) -> model.Activity {
  model.Activity(
    id:,
    title: model.BilingualString(sv: "Climb", en: "Climb"),
    description: model.BilingualString(sv: "Desc", en: "Desc"),
    max_attendees: max,
    start_time: timestamp.from_unix_seconds(1_750_000_000),
    end_time: timestamp.from_unix_seconds(1_750_003_600),
    location: None,
    tags: [],
    target_groups: [],
    cancellation: None,
  )
}

fn a_location(id: Uuid, name: String) -> model.Location {
  model.Location(
    id:,
    name: model.BilingualString(sv: name, en: name),
    description: model.BilingualString(sv: "", en: ""),
    icon_name: "pin",
    icon_variant: "outline",
    color: "#000000",
    latitude: 0.0,
    longitude: 0.0,
    opening_hours: json.object([]),
    tags: [],
  )
}

/// The detail-only slice of `an_activity` — description "Desc", no location.
fn a_detail() -> client.ActivityDetail {
  client.ActivityDetail(
    description: model.BilingualString(sv: "Desc", en: "Desc"),
    location: None,
  )
}

fn a_booking(id: Uuid, activity_id: Uuid) -> model.Booking {
  model.Booking(
    id:,
    user_id: id_a(),
    activity_id:,
    booker_name: "Ada",
    booker_group_id: Some(1),
    booker_group_name: Some("Group"),
    group_free_text: "",
    responsible_name: "Ada",
    phone_number: "0700000000",
    participant_count: 2,
  )
}

/// A fixed "today" for tests, inside the event range, so browse window keys are
/// deterministic.
fn test_today() -> calendar.Date {
  calendar.Date(2026, calendar.July, 25)
}

/// The default Activities browse window key for `base_model` (a manager, so
/// `include_call_offs` is `True`) on the default day (`test_today`).
fn activities_window() -> client.WindowKey {
  #(client.SourceActivities, Some(test_today()), True)
}

fn beach_bus_window() -> client.WindowKey {
  #(client.SourceBeachBus, Some(test_today()), True)
}

fn climbing_wall_window() -> client.WindowKey {
  #(client.SourceClimbingWall, Some(test_today()), True)
}

/// Filters on the default activities list, scoped to `tab`.
fn filters_for(tab: client.ActivitiesFilterTab) -> client.ListFilters {
  client.ListFilters(..client.default_filters(), tab:)
}

/// A logged-in user on the default activities list. The default Activities
/// window loads eagerly; every other tab/day starts absent (`NotAsked`).
fn base_model() -> client.Model {
  client.Model(
    page: client.ActivitiesListPage(client.default_filters()),
    translator: client.translator_for("sv"),
    activities: dict.new(),
    windows: dict.from_list([#(activities_window(), client.Loading)]),
    etags: dict.new(),
    today: test_today(),
    browse_day_filter: None,
    favourites_day_filter: None,
    details: dict.new(),
    statuses: dict.new(),
    spots: dict.new(),
    activity_tags: dict.new(),
    locations: dict.new(),
    roles: [client.ManageActivities],
    booker: client.IdentityUnknown,
    edit_ui: client.default_edit_ui(),
  )
}

/// A model on the management list with a given form overlay open (or closed).
fn manage_model(activity_form: client.ActivityFormState) -> client.Model {
  client.Model(
    ..base_model(),
    page: client.ManageActivitiesPage(client.default_filters(), activity_form),
  )
}

fn parse_uri(path: String) -> uri.Uri {
  let assert Ok(u) = uri.parse(path)
  u
}

// PURE HELPERS: relative_url ---------------------------------------------------

pub fn relative_url_strips_scheme_and_host_test() {
  let u =
    uri.Uri(
      scheme: Some("https"),
      userinfo: None,
      host: Some("example.com"),
      port: Some(443),
      path: "/_services/booking/activities/abc",
      query: None,
      fragment: None,
    )
  assert client.relative_url(u) == "/_services/booking/activities/abc"
}

pub fn relative_url_keeps_query_and_fragment_test() {
  let u =
    uri.Uri(
      scheme: Some("https"),
      userinfo: None,
      host: Some("example.com"),
      port: None,
      path: "/foo",
      query: Some("x=1&y=2"),
      fragment: Some("section"),
    )
  assert client.relative_url(u) == "/foo?x=1&y=2#section"
}

pub fn relative_url_drops_userinfo_test() {
  let u =
    uri.Uri(
      scheme: Some("https"),
      userinfo: Some("user:pass"),
      host: Some("example.com"),
      port: None,
      path: "/activities/abc",
      query: None,
      fragment: None,
    )
  assert client.relative_url(u) == "/activities/abc"
}

// PURE HELPERS: toggle_member --------------------------------------------------

pub fn toggle_member_adds_when_absent_test() {
  assert client.toggle_member(["a"], "b") == ["b", "a"]
}

pub fn toggle_member_removes_when_present_test() {
  assert client.toggle_member(["a", "b"], "a") == ["b"]
}

// PURE HELPERS: tab index round-trip -------------------------------------------

pub fn tab_index_round_trips_test() {
  assert client.tab_from_index(client.tab_index(client.TabFavourites))
    == client.TabFavourites
}

pub fn tab_from_index_out_of_range_falls_back_to_activities_test() {
  assert client.tab_from_index(99) == client.TabActivities
}

pub fn tab_source_maps_each_tab_test() {
  assert client.tab_source(client.TabActivities) == client.SourceActivities
  assert client.tab_source(client.TabBeachBus) == client.SourceBeachBus
  assert client.tab_source(client.TabClimbingWall) == client.SourceClimbingWall
  assert client.tab_source(client.TabFavourites) == client.SourceFavourites
}

pub fn both_lists_show_the_same_tabs_including_favourites_test() {
  // Browse and manage share one tab set; the management list shows Favourites
  // too (issue #42).
  let tabs = client.list_tabs()
  assert list.contains(tabs, client.TabActivities)
  assert list.contains(tabs, client.TabBeachBus)
  assert list.contains(tabs, client.TabClimbingWall)
  assert list.contains(tabs, client.TabFavourites)
}

// PURE HELPERS: status accessors -----------------------------------------------

pub fn status_of_defaults_to_not_interested_test() {
  assert client.status_of(dict.new(), id_a()) == model.NotInterested
}

pub fn is_favourited_covers_booked_and_favourited_test() {
  let b = a_booking(id_a(), id_b())
  assert client.is_favourited(model.Booked(b)) == True
  assert client.is_favourited(model.Favourited) == True
  assert client.is_favourited(model.NotInterested) == False
}

pub fn is_booked_only_true_for_booked_test() {
  let b = a_booking(id_a(), id_b())
  assert client.is_booked(model.Booked(b)) == True
  assert client.is_booked(model.Favourited) == False
  assert client.is_booked(model.NotInterested) == False
}

pub fn booking_of_extracts_booking_test() {
  let b = a_booking(id_a(), id_b())
  assert client.booking_of(model.Booked(b)) == Some(b)
  assert client.booking_of(model.Favourited) == None
}

// PURE HELPERS: id-window cache (RemoteData(List(Uuid))) -----------------------

pub fn remove_id_drops_from_loaded_window_test() {
  assert client.remove_id(client.Loaded([id_a(), id_b()]), id_a())
    == client.Loaded([id_b()])
}

pub fn remove_id_is_noop_unless_loaded_test() {
  assert client.remove_id(client.NotAsked, id_a()) == client.NotAsked
}

pub fn hydrate_inserts_and_overwrites_by_id_test() {
  let original = a_summary(id_a(), "Old", None)
  let updated = a_summary(id_a(), "New", None)
  let store = client.hydrate(dict.new(), [original])
  assert dict.get(store, id_a()) == Ok(original)
  assert dict.get(client.hydrate(store, [updated]), id_a()) == Ok(updated)
}

// PURE HELPERS: classify_interval ----------------------------------------------

pub fn classify_interval_same_day_same_time_test() {
  let d = calendar.Date(2026, calendar.August, 1)
  let t = calendar.TimeOfDay(10, 0, 0, 0)
  assert client.classify_interval(#(d, t), #(d, t)) == client.SameDaySameTime
}

pub fn classify_interval_same_day_different_time_test() {
  let d = calendar.Date(2026, calendar.August, 1)
  let t1 = calendar.TimeOfDay(10, 0, 0, 0)
  let t2 = calendar.TimeOfDay(12, 0, 0, 0)
  assert client.classify_interval(#(d, t1), #(d, t2))
    == client.SameDayDifferentTime
}

pub fn classify_interval_different_days_test() {
  let d1 = calendar.Date(2026, calendar.August, 1)
  let d2 = calendar.Date(2026, calendar.August, 2)
  let t = calendar.TimeOfDay(10, 0, 0, 0)
  assert client.classify_interval(#(d1, t), #(d2, t)) == client.DifferentDays
}

// PURE HELPERS: apply_filters --------------------------------------------------
// Tab/favourites membership is resolved upstream now, so apply_filters only
// covers search + day + the mock facets.

pub fn apply_filters_default_keeps_everything_test() {
  let a =
    client.CardItem(a_summary(id_a(), "A", None), model.NotInterested, None)
  let b =
    client.CardItem(a_summary(id_b(), "B", None), model.NotInterested, None)
  assert client.apply_filters([a, b], client.default_filters(), None) == [a, b]
}

pub fn apply_filters_matches_title_case_insensitively_test() {
  let climb =
    client.CardItem(
      a_summary(id_a(), "Klättring", None),
      model.NotInterested,
      None,
    )
  let swim =
    client.CardItem(
      a_summary(id_b(), "Simning", None),
      model.NotInterested,
      None,
    )
  let filters = client.ListFilters(..client.default_filters(), search: "KLÄTT")
  assert client.apply_filters([climb, swim], filters, None) == [climb]
}

// LIST DERIVATION: tab_summaries -----------------------------------------------

pub fn tab_summaries_browse_maps_id_window_through_cache_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let summary_b = a_summary(id_b(), "B", None)
  let model_ =
    client.set_window_remote(
      client.Model(
        ..base_model(),
        activities: dict.from_list([
          #(id_a(), summary_a),
          #(id_b(), summary_b),
        ]),
      ),
      activities_window(),
      client.Loaded([id_a(), id_b()]),
    )
  assert client.tab_summaries(
      model_,
      filters_for(client.TabActivities),
      client.ActivitiesListPage(client.default_filters()),
    )
    == client.Loaded([summary_a, summary_b])
}

pub fn tab_summaries_browse_drops_uncached_ids_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let model_ =
    client.set_window_remote(
      client.Model(
        ..base_model(),
        activities: dict.from_list([#(id_a(), summary_a)]),
      ),
      // id_b is in the window but not yet in the entity cache.
      activities_window(),
      client.Loaded([id_a(), id_b()]),
    )
  assert client.tab_summaries(
      model_,
      filters_for(client.TabActivities),
      client.ActivitiesListPage(client.default_filters()),
    )
    == client.Loaded([summary_a])
}

pub fn tab_summaries_browse_reflects_fetch_state_test() {
  assert client.tab_summaries(
      base_model(),
      filters_for(client.TabBeachBus),
      client.ActivitiesListPage(client.default_filters()),
    )
    == client.NotAsked
}

pub fn tab_summaries_favourites_derived_from_statuses_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let summary_b = a_summary(id_b(), "B", None)
  let booking = a_booking(id_c(), id_b())
  let model_ =
    client.set_window_remote(
      client.Model(
        ..base_model(),
        activities: dict.from_list([
          #(id_a(), summary_a),
          #(id_b(), summary_b),
        ]),
        statuses: dict.from_list([
          #(id_a(), model.Favourited),
          #(id_b(), model.Booked(booking)),
        ]),
      ),
      client.favourites_key(),
      client.Loaded([]),
    )
  let assert client.Loaded(summaries) =
    client.tab_summaries(
      model_,
      filters_for(client.TabFavourites),
      client.ActivitiesListPage(client.default_filters()),
    )
  // dict key order is unspecified, so assert membership rather than order.
  assert list.length(summaries) == 2
  assert list.contains(summaries, summary_a)
  assert list.contains(summaries, summary_b)
}

pub fn tab_summaries_favourites_empty_reflects_fetch_state_test() {
  // Nothing favourited yet => mirror the favourites window fetch state.
  assert client.tab_summaries(
      base_model(),
      filters_for(client.TabFavourites),
      client.ActivitiesListPage(client.default_filters()),
    )
    == client.NotAsked
  let loading =
    client.set_window_remote(
      base_model(),
      client.favourites_key(),
      client.Loading,
    )
  assert client.tab_summaries(
      loading,
      filters_for(client.TabFavourites),
      client.ActivitiesListPage(client.default_filters()),
    )
    == client.Loading
}

pub fn tab_summaries_browse_hides_called_off_manage_shows_it_test() {
  let active = a_summary(id_a(), "Active", None)
  let called_off =
    model.ActivitySummary(
      ..a_summary(id_b(), "Called off", None),
      cancellation: Some("Inställd"),
    )
  let model_ =
    client.set_window_remote(
      client.Model(
        ..base_model(),
        activities: dict.from_list([#(id_a(), active), #(id_b(), called_off)]),
      ),
      activities_window(),
      client.Loaded([id_a(), id_b()]),
    )
  // Browse: the called-off activity is filtered out.
  assert client.tab_summaries(
      model_,
      filters_for(client.TabActivities),
      client.ActivitiesListPage(client.default_filters()),
    )
    == client.Loaded([active])
  // Manage: both are shown.
  assert client.tab_summaries(
      model_,
      filters_for(client.TabActivities),
      client.ManageActivitiesPage(
        client.default_filters(),
        client.ActivityFormClosed,
      ),
    )
    == client.Loaded([active, called_off])
}

// LIST WINDOWS: window_remote / set_window_remote / load_or_revalidate ---------

pub fn set_then_get_window_remote_round_trips_test() {
  let model_ =
    client.set_window_remote(
      base_model(),
      climbing_wall_window(),
      client.Loaded([id_a()]),
    )
  assert client.window_remote(model_, climbing_wall_window())
    == client.Loaded([id_a()])
}

pub fn load_or_revalidate_marks_unasked_window_loading_test() {
  let #(next, _) = client.load_or_revalidate(base_model(), beach_bus_window())
  assert client.window_remote(next, beach_bus_window()) == client.Loading
}

pub fn load_or_revalidate_keeps_loaded_window_while_revalidating_test() {
  let model_ =
    client.set_window_remote(
      base_model(),
      beach_bus_window(),
      client.Loaded([id_a()]),
    )
  let #(next, _) = client.load_or_revalidate(model_, beach_bus_window())
  // Still shows the cached list (revalidation happens in the background).
  assert client.window_remote(next, beach_bus_window())
    == client.Loaded([id_a()])
}

// ROUTING: uri_to_page ---------------------------------------------------------

pub fn uri_to_page_lists_activities_test() {
  let #(page, _) =
    client.uri_to_page(parse_uri("/_services/booking/activities"), dict.new())
  assert page == client.ActivitiesListPage(client.default_filters())
}

// The create/edit form is a drawer overlay opened by a message, not a route, so
// the old `/new` and `/:id/edit` paths no longer resolve to a page.
pub fn uri_to_page_new_activity_route_removed_test() {
  let #(page, _) =
    client.uri_to_page(
      parse_uri("/_services/booking/activities/new"),
      dict.new(),
    )
  assert page == client.NotFoundPage
}

pub fn uri_to_page_edit_activity_route_removed_test() {
  let path =
    "/_services/booking/activities/" <> uuid.to_string(id_a()) <> "/edit"
  let #(page, _) = client.uri_to_page(parse_uri(path), dict.new())
  assert page == client.NotFoundPage
}

pub fn new_activity_click_opens_form_drawer_test() {
  let #(next, _) =
    client.update(
      manage_model(client.ActivityFormClosed),
      client.UserClickedNewActivity,
    )
  let assert client.ActivityFormNew(_, submit_error, _, _) =
    client.activity_form_of(next)
  assert submit_error == None
}

pub fn edit_activity_click_opens_loading_drawer_test() {
  let #(next, _) =
    client.update(
      manage_model(client.ActivityFormClosed),
      client.UserClickedEditActivity(id_a()),
    )
  assert client.activity_form_of(next)
    == client.ActivityFormEdit(id_a(), client.EditLoading)
}

pub fn cancel_edit_closes_form_drawer_test() {
  let model_ = manage_model(client.ActivityFormEdit(id_a(), client.EditLoading))
  let #(next, _) = client.update(model_, client.UserClickedCancelEdit)
  assert client.activity_form_of(next) == client.ActivityFormClosed
}

pub fn uri_to_page_detail_for_valid_uuid_test() {
  let path = "/_services/booking/activities/" <> uuid.to_string(id_a())
  let #(page, _) = client.uri_to_page(parse_uri(path), dict.new())
  let assert client.ActivityDetailPage(_, booking) = page
  assert booking == client.BookingClosed
}

pub fn uri_to_page_not_found_for_invalid_uuid_test() {
  let #(page, _) =
    client.uri_to_page(
      parse_uri("/_services/booking/activities/not-a-uuid"),
      dict.new(),
    )
  assert page == client.NotFoundPage
}

pub fn uri_to_page_bookings_for_valid_uuid_test() {
  let path =
    "/_services/booking/activities/" <> uuid.to_string(id_a()) <> "/bookings"
  let #(page, _) = client.uri_to_page(parse_uri(path), dict.new())
  assert page == client.ActivityBookingsPage(id_a(), client.Loading)
}

pub fn uri_to_page_manage_lists_activities_in_manage_mode_test() {
  let #(page, _) =
    client.uri_to_page(
      parse_uri("/_services/booking/activities/manage"),
      dict.new(),
    )
  assert page
    == client.ManageActivitiesPage(
      client.default_filters(),
      client.ActivityFormClosed,
    )
}

// UPDATE: favourite toggle (optimistic) ----------------------------------------

pub fn toggling_favourite_marks_unfavourited_as_favourited_test() {
  let #(next, _) =
    client.update(base_model(), client.UserToggledFavourite(id_a()))
  assert dict.get(next.statuses, id_a()) == Ok(model.Favourited)
}

pub fn toggling_favourite_invalidates_favourited_window_test() {
  let model_ =
    client.set_window_remote(
      base_model(),
      client.favourites_key(),
      client.Loaded([]),
    )
  let #(next, _) = client.update(model_, client.UserToggledFavourite(id_a()))
  assert client.window_remote(next, client.favourites_key()) == client.NotAsked
}

pub fn toggling_favourite_removes_existing_favourite_test() {
  let model_ =
    client.Model(
      ..base_model(),
      statuses: dict.from_list([#(id_a(), model.Favourited)]),
    )
  let #(next, _) = client.update(model_, client.UserToggledFavourite(id_a()))
  assert dict.get(next.statuses, id_a()) == Error(Nil)
}

pub fn toggling_favourite_is_locked_while_booked_test() {
  let statuses =
    dict.from_list([#(id_a(), model.Booked(a_booking(id_b(), id_a())))])
  let model_ = client.Model(..base_model(), statuses:)
  let #(next, _) = client.update(model_, client.UserToggledFavourite(id_a()))
  assert next.statuses == statuses
}

// UPDATE: favourite revert on API error ----------------------------------------

pub fn failed_favourite_add_is_reverted_test() {
  let model_ =
    client.Model(
      ..base_model(),
      statuses: dict.from_list([#(id_a(), model.Favourited)]),
    )
  let #(next, _) =
    client.update(
      model_,
      client.ApiToggledFavourite(id_a(), True, Error(rsvp.BadBody)),
    )
  assert dict.get(next.statuses, id_a()) == Error(Nil)
}

pub fn failed_favourite_removal_is_restored_test() {
  let #(next, _) =
    client.update(
      base_model(),
      client.ApiToggledFavourite(id_a(), False, Error(rsvp.BadBody)),
    )
  assert dict.get(next.statuses, id_a()) == Ok(model.Favourited)
}

// UPDATE: booking state machine ------------------------------------------------

pub fn clicking_book_with_capacity_opens_form_test() {
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.BookingClosed),
      activities: dict.from_list([#(id_a(), a_summary(id_a(), "A", Some(10)))]),
      details: dict.from_list([#(id_a(), client.Loaded(a_detail()))]),
    )
  let #(next, _) = client.update(model_, client.UserClickedBook)
  let assert client.ActivityDetailPage(_, client.BookingOpen(_, error, mode)) =
    next.page
  assert error == None
  assert mode == client.BookingNew
}

pub fn clicking_book_without_capacity_submits_directly_test() {
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.BookingClosed),
      activities: dict.from_list([#(id_a(), a_summary(id_a(), "A", None))]),
      details: dict.from_list([#(id_a(), client.Loaded(a_detail()))]),
    )
  let #(next, _) = client.update(model_, client.UserClickedBook)
  let assert client.ActivityDetailPage(_, client.BookingSubmitting(mode)) =
    next.page
  assert mode == client.BookingNew
}

pub fn clicking_change_booking_opens_edit_form_test() {
  let booking = a_booking(id_b(), id_a())
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.BookingClosed),
      statuses: dict.from_list([#(id_a(), model.Booked(booking))]),
    )
  let #(next, _) = client.update(model_, client.UserClickedChangeBooking)
  let assert client.ActivityDetailPage(_, client.BookingOpen(_, _, mode)) =
    next.page
  assert mode == client.BookingEdit(id_b())
}

pub fn clicking_unbook_asks_for_confirmation_test() {
  let booking = a_booking(id_b(), id_a())
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.BookingClosed),
      statuses: dict.from_list([#(id_a(), model.Booked(booking))]),
    )
  let #(next, _) = client.update(model_, client.UserClickedUnbook)
  assert next.page
    == client.ActivityDetailPage(id_a(), client.UnbookConfirming(id_b()))
}

pub fn confirming_unbook_moves_to_submitting_test() {
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.UnbookConfirming(id_b())),
    )
  let #(next, _) = client.update(model_, client.UserClickedConfirmUnbook)
  assert next.page
    == client.ActivityDetailPage(id_a(), client.UnbookSubmitting(id_b()))
}

pub fn cancelling_unbook_closes_booking_test() {
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.UnbookConfirming(id_b())),
    )
  let #(next, _) = client.update(model_, client.UserClickedCancelUnbook)
  assert next.page == client.ActivityDetailPage(id_a(), client.BookingClosed)
}

// UPDATE: booking API results --------------------------------------------------

pub fn created_booking_records_booked_status_and_invalidates_favourites_test() {
  let booking = a_booking(id_b(), id_a())
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(
        id_a(),
        client.BookingSubmitting(client.BookingNew),
      ),
    )
  let model_ =
    client.set_window_remote(model_, client.favourites_key(), client.Loaded([]))
  let #(next, _) = client.update(model_, client.ApiCreatedBooking(Ok(booking)))
  assert dict.get(next.statuses, id_a()) == Ok(model.Booked(booking))
  assert client.window_remote(next, client.favourites_key()) == client.NotAsked
  assert next.page == client.ActivityDetailPage(id_a(), client.BookingClosed)
}

pub fn deleted_booking_downgrades_to_favourited_test() {
  let booking = a_booking(id_b(), id_a())
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.UnbookSubmitting(id_b())),
      statuses: dict.from_list([#(id_a(), model.Booked(booking))]),
    )
  let #(next, _) =
    client.update(model_, client.ApiDeletedBooking(id_a(), id_b(), Ok(Nil)))
  assert dict.get(next.statuses, id_a()) == Ok(model.Favourited)
  assert next.page == client.ActivityDetailPage(id_a(), client.BookingClosed)
}

// UPDATE: bookings list fetch --------------------------------------------------

pub fn returned_bookings_land_on_matching_page_test() {
  let booking = a_booking(id_c(), id_a())
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityBookingsPage(id_a(), client.Loading),
    )
  let #(next, _) =
    client.update(model_, client.ApiReturnedBookings(id_a(), Ok([booking])))
  assert next.page
    == client.ActivityBookingsPage(id_a(), client.Loaded([booking]))
}

pub fn returned_bookings_dropped_for_other_activity_test() {
  // A response for id_b arrives while the open page shows id_a's bookings —
  // it's stale and must not overwrite the current page.
  let booking = a_booking(id_c(), id_b())
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityBookingsPage(id_a(), client.Loading),
    )
  let #(next, _) =
    client.update(model_, client.ApiReturnedBookings(id_b(), Ok([booking])))
  assert next.page == client.ActivityBookingsPage(id_a(), client.Loading)
}

pub fn failed_bookings_fetch_marks_failed_test() {
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityBookingsPage(id_a(), client.Loading),
    )
  let #(next, _) =
    client.update(
      model_,
      client.ApiReturnedBookings(id_a(), Error(rsvp.BadBody)),
    )
  assert next.page
    == client.ActivityBookingsPage(
      id_a(),
      client.Failed(client.LoadBookingsFailed),
    )
}

// UPDATE: statuses fetch -------------------------------------------------------

pub fn returned_statuses_are_folded_into_dict_test() {
  let booking = a_booking(id_c(), id_b())
  let entries = [
    model.ActivityStatusEntry(id_a(), model.Favourited),
    model.ActivityStatusEntry(id_b(), model.Booked(booking)),
  ]
  let #(next, _) =
    client.update(base_model(), client.ApiReturnedStatuses(Ok(entries)))
  assert dict.get(next.statuses, id_a()) == Ok(model.Favourited)
  assert dict.get(next.statuses, id_b()) == Ok(model.Booked(booking))
}

pub fn failed_statuses_fetch_keeps_prior_dict_test() {
  let statuses = dict.from_list([#(id_a(), model.Favourited)])
  let model_ = client.Model(..base_model(), statuses:)
  let #(next, _) =
    client.update(model_, client.ApiReturnedStatuses(Error(rsvp.BadBody)))
  assert next.statuses == statuses
}

// UPDATE: activity list responses ----------------------------------------------

pub fn returned_activity_list_hydrates_cache_and_sets_window_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let summary_b = a_summary(id_b(), "B", None)
  let #(next, _) =
    client.update(
      base_model(),
      client.ApiReturnedActivityWindow(
        beach_bus_window(),
        client.WindowLoaded([summary_a, summary_b], Some("\"etag-1\"")),
      ),
    )
  assert client.window_remote(next, beach_bus_window())
    == client.Loaded([id_a(), id_b()])
  assert dict.get(next.activities, id_a()) == Ok(summary_a)
  assert dict.get(next.activities, id_b()) == Ok(summary_b)
  // The response's ETag is stored keyed by the whole window key.
  assert dict.get(next.etags, beach_bus_window()) == Ok("\"etag-1\"")
}

pub fn unchanged_activity_window_keeps_cache_untouched_test() {
  // A 304 leaves the loaded window and its cached summaries exactly as they were.
  let summary_a = a_summary(id_a(), "A", None)
  let model_ =
    client.set_window_remote(
      client.Model(
        ..base_model(),
        activities: dict.from_list([#(id_a(), summary_a)]),
      ),
      beach_bus_window(),
      client.Loaded([id_a()]),
    )
  let #(next, _) =
    client.update(
      model_,
      client.ApiReturnedActivityWindow(
        beach_bus_window(),
        client.WindowUnchanged,
      ),
    )
  assert client.window_remote(next, beach_bus_window())
    == client.Loaded([id_a()])
  assert dict.get(next.activities, id_a()) == Ok(summary_a)
}

pub fn list_refetch_refreshes_summary_without_touching_loaded_detail_test() {
  // A list response refreshes the summary in `activities` while a loaded detail
  // in `details` is preserved — the two caches can't drift because the summary
  // has exactly one home. `detail_of` composes the fresh summary + this detail.
  let model_ =
    client.Model(
      ..base_model(),
      activities: dict.from_list([#(id_a(), a_summary(id_a(), "Old", None))]),
      details: dict.from_list([#(id_a(), client.Loaded(a_detail()))]),
    )
  let refreshed = a_summary(id_a(), "New", Some(20))
  let #(next, _) =
    client.update(
      model_,
      client.ApiReturnedActivityWindow(
        activities_window(),
        client.WindowLoaded([refreshed], None),
      ),
    )
  assert dict.get(next.activities, id_a()) == Ok(refreshed)
  assert dict.get(next.details, id_a()) == Ok(client.Loaded(a_detail()))
}

pub fn failed_activity_list_marks_source_failed_test() {
  let #(next, _) =
    client.update(
      base_model(),
      client.ApiReturnedActivityWindow(
        climbing_wall_window(),
        client.WindowFailed,
      ),
    )
  let assert client.Failed(_) =
    client.window_remote(next, climbing_wall_window())
}

pub fn created_activity_caches_summary_and_invalidates_browse_windows_test() {
  // A create can't be mapped to a single day/kind window, so every browse window
  // is dropped; the summary + detail are cached. Closing the form then refreshes
  // the list's current window in place (→ Loading), so the new activity shows
  // without a navigation; the other dropped windows stay NotAsked until reopened.
  let model_ =
    client.set_window_remote(
      client.set_window_remote(
        client.set_window_remote(
          base_model(),
          activities_window(),
          client.Loaded([id_b()]),
        ),
        beach_bus_window(),
        client.Loaded([id_b()]),
      ),
      climbing_wall_window(),
      client.Loaded([id_b()]),
    )
  let activity = an_activity(id_a(), Some(5))
  let #(next, _) =
    client.update(model_, client.ApiCreatedActivity(Ok(activity)))
  assert client.window_remote(next, activities_window()) == client.Loading
  assert client.window_remote(next, beach_bus_window()) == client.NotAsked
  assert client.window_remote(next, climbing_wall_window()) == client.NotAsked
  // The summary lands in `activities`; only the detail-only fields in `details`.
  assert dict.get(next.activities, id_a())
    == Ok(a_summary(id_a(), "Climb", Some(5)))
  assert dict.get(next.details, id_a()) == Ok(client.Loaded(a_detail()))
}

pub fn deleted_activity_purges_caches_and_all_windows_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let summary_b = a_summary(id_b(), "B", None)
  let model_ =
    client.set_window_remote(
      client.set_window_remote(
        client.Model(
          ..base_model(),
          activities: dict.from_list([
            #(id_a(), summary_a),
            #(id_b(), summary_b),
          ]),
          statuses: dict.from_list([#(id_a(), model.Favourited)]),
        ),
        activities_window(),
        client.Loaded([id_a(), id_b()]),
      ),
      beach_bus_window(),
      client.Loaded([id_a()]),
    )
  let #(next, _) =
    client.update(model_, client.ApiDeletedActivity(id_a(), Ok(Nil)))
  // The id is dropped from every cached window at once.
  assert client.window_remote(next, activities_window())
    == client.Loaded([id_b()])
  assert client.window_remote(next, beach_bus_window()) == client.Loaded([])
  assert dict.has_key(next.activities, id_a()) == False
  assert dict.get(next.statuses, id_a()) == Error(Nil)
}

// UPDATE: list filters & tabs --------------------------------------------------

pub fn selecting_tab_updates_filter_and_lazily_loads_source_test() {
  // index 1 == TabBeachBus, whose window starts absent in base_model.
  let #(next, _) = client.update(base_model(), client.UserSelectedTab(1))
  let assert client.ActivitiesListPage(filters) = next.page
  assert filters.tab == client.TabBeachBus
  assert client.window_remote(next, beach_bus_window()) == client.Loading
}

pub fn selecting_tab_stays_on_manage_page_test() {
  // The manage list reuses the whole browse view, so switching tabs must keep
  // the page a `ManageActivitiesPage` (cards keep opening the edit drawer).
  let manage = manage_model(client.ActivityFormClosed)
  let #(next, _) = client.update(manage, client.UserSelectedTab(1))
  let assert client.ManageActivitiesPage(filters, _) = next.page
  assert filters.tab == client.TabBeachBus
}

pub fn retrying_load_marks_current_tab_source_loading_test() {
  let model_ =
    client.set_window_remote(
      base_model(),
      activities_window(),
      client.Failed(client.LoadActivitiesFailed),
    )
  let #(next, _) = client.update(model_, client.UserClickedRetryLoad)
  assert client.window_remote(next, activities_window()) == client.Loading
}

// UPDATE: day filter persistence (issue #40) -----------------------------------

/// A second in-range event day, distinct from `test_today`, for exercising the
/// per-view day fields.
fn other_day() -> calendar.Date {
  calendar.Date(2026, calendar.July, 27)
}

pub fn selecting_day_on_browse_sets_browse_day_and_fetches_window_test() {
  // On a browse tab, picking a day persists it to `browse_day_filter` (leaving
  // Favourites' own day untouched) and fetches that day's window.
  let #(next, _) =
    client.update(base_model(), client.UserSelectedDay(Some(other_day())))
  assert next.browse_day_filter == Some(other_day())
  assert next.favourites_day_filter == None
  let day_window = #(client.SourceActivities, Some(other_day()), True)
  assert client.window_remote(next, day_window) == client.Loading
}

fn favourites_model() -> client.Model {
  client.Model(
    ..base_model(),
    page: client.ActivitiesListPage(filters_for(client.TabFavourites)),
  )
}

pub fn selecting_concrete_day_on_favourites_also_moves_browse_day_test() {
  // Picking a concrete day on Favourites carries the browse day along, so
  // switching back to a browse tab lands on the same day.
  let #(next, _) =
    client.update(favourites_model(), client.UserSelectedDay(Some(other_day())))
  assert next.favourites_day_filter == Some(other_day())
  assert next.browse_day_filter == Some(other_day())
}

pub fn selecting_all_days_on_favourites_leaves_browse_day_untouched_test() {
  // "All days" (`None`) on Favourites must not clobber a browse day the user set.
  let model_ =
    client.Model(..favourites_model(), browse_day_filter: Some(other_day()))
  let #(next, _) = client.update(model_, client.UserSelectedDay(None))
  assert next.favourites_day_filter == None
  assert next.browse_day_filter == Some(other_day())
}

pub fn browse_day_survives_page_rebuild_via_route_change_test() {
  // The core of issue #40: after picking a day, navigating away and back must
  // keep it. The day now lives on the Model, not the (rebuilt) page filters, so
  // the window key resolved after the round-trip still targets the chosen day.
  let #(picked, _) =
    client.update(base_model(), client.UserSelectedDay(Some(other_day())))
  let #(detail, _) =
    client.update(
      picked,
      client.OnRouteChange(parse_uri(
        "/_services/booking/activities/" <> uuid.to_string(id_a()),
      )),
    )
  let #(back, _) =
    client.update(
      detail,
      client.OnRouteChange(parse_uri("/_services/booking/activities")),
    )
  assert back.browse_day_filter == Some(other_day())
  let day_window = #(client.SourceActivities, Some(other_day()), True)
  assert client.window_remote(back, day_window) == client.Loading
}

pub fn effective_day_is_independent_per_view_test() {
  // Browse and Favourites resolve their day from separate Model fields, so one
  // can sit on a picked day while the other stays on its default.
  let model_ =
    client.Model(
      ..base_model(),
      browse_day_filter: Some(other_day()),
      favourites_day_filter: None,
    )
  assert client.effective_day(model_, client.TabActivities) == Some(other_day())
  // Favourites' default is all days (`None`), independent of the browse pick.
  assert client.effective_day(model_, client.TabFavourites) == None
  // A browse tab with no pick falls back to today.
  assert client.effective_day(base_model(), client.TabActivities)
    == Some(test_today())
}

pub fn searching_updates_filters_on_list_page_test() {
  let #(next, _) =
    client.update(base_model(), client.UserSearchedActivities("bad"))
  let assert client.ActivitiesListPage(filters) = next.page
  assert filters.search == "bad"
}

pub fn searching_is_noop_off_the_list_page_test() {
  let model_ =
    client.Model(
      ..base_model(),
      page: client.ActivityDetailPage(id_a(), client.BookingClosed),
    )
  let #(next, _) = client.update(model_, client.UserSearchedActivities("bad"))
  assert next.page == model_.page
}

// UPDATE: location combobox ----------------------------------------------------

pub fn location_search_sets_query_and_opens_test() {
  let #(next, _) =
    client.update(base_model(), client.UserSearchedLocation("info"))
  assert next.edit_ui.location_query == "info"
  assert next.edit_ui.location_open == True
}

pub fn location_open_from_closed_clears_query_test() {
  let model_ =
    client.Model(
      ..base_model(),
      edit_ui: client.EditUi(
        ..client.default_edit_ui(),
        location_query: "stale",
      ),
    )
  let #(next, _) = client.update(model_, client.UserOpenedLocationDropdown)
  assert next.edit_ui.location_query == ""
  assert next.edit_ui.location_open == True
}

pub fn location_open_while_open_keeps_query_test() {
  let model_ =
    client.Model(
      ..base_model(),
      edit_ui: client.EditUi(
        ..client.default_edit_ui(),
        location_query: "info",
        location_open: True,
      ),
    )
  let #(next, _) = client.update(model_, client.UserOpenedLocationDropdown)
  assert next.edit_ui.location_query == "info"
  assert next.edit_ui.location_open == True
}

pub fn location_select_sets_choice_clears_query_and_closes_test() {
  let model_ =
    client.Model(
      ..base_model(),
      edit_ui: client.EditUi(
        ..client.default_edit_ui(),
        location_query: "info",
        location_open: True,
      ),
    )
  let #(next, _) =
    client.update(model_, client.UserSelectedLocation(Some(id_a())))
  assert next.edit_ui.location_id == Some(id_a())
  assert next.edit_ui.location_query == ""
  assert next.edit_ui.location_open == False
}

pub fn location_select_none_clears_choice_test() {
  let model_ =
    client.Model(
      ..base_model(),
      edit_ui: client.EditUi(
        ..client.default_edit_ui(),
        location_id: Some(id_a()),
        location_open: True,
      ),
    )
  let #(next, _) = client.update(model_, client.UserSelectedLocation(None))
  assert next.edit_ui.location_id == None
  assert next.edit_ui.location_open == False
}

pub fn location_blur_closes_dropdown_test() {
  let model_ =
    client.Model(
      ..base_model(),
      edit_ui: client.EditUi(..client.default_edit_ui(), location_open: True),
    )
  let #(next, _) = client.update(model_, client.UserClosedLocationDropdown)
  assert next.edit_ui.location_open == False
}

// UPDATE: edit form location seeding ------------------------------------------

pub fn edit_open_seeds_location_id_from_activity_test() {
  let activity =
    model.Activity(
      ..an_activity(id_a(), None),
      location: Some(a_location(id_b(), "HQ")),
    )
  let model_ = manage_model(client.ActivityFormEdit(id_a(), client.EditLoading))
  let #(next, _) =
    client.update(model_, client.ApiReturnedActivity(id_a(), Ok(activity)))
  assert next.edit_ui.location_id == Some(id_b())
}

pub fn edit_open_seeds_none_when_activity_has_no_location_test() {
  let model_ = manage_model(client.ActivityFormEdit(id_a(), client.EditLoading))
  let #(next, _) =
    client.update(
      model_,
      client.ApiReturnedActivity(id_a(), Ok(an_activity(id_a(), None))),
    )
  assert next.edit_ui.location_id == None
}

pub fn detail_fetch_caches_activity_location_test() {
  let location = a_location(id_b(), "HQ")
  let activity =
    model.Activity(..an_activity(id_a(), None), location: Some(location))
  let #(next, _) =
    client.update(
      base_model(),
      client.ApiReturnedActivity(id_a(), Ok(activity)),
    )
  assert dict.get(next.locations, id_b()) == Ok(location)
}
