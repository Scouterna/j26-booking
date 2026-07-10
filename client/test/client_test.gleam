import client
import gleam/dict
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
  )
}

/// The detail-only slice of `an_activity` — description "Desc", no location.
fn a_detail() -> client.ActivityDetail {
  client.ActivityDetail(
    description: model.BilingualString(sv: "Desc", en: "Desc"),
    location: None,
    tags: [],
    target_groups: [],
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

/// A logged-in user on the default activities list. The default tab
/// (`activities_ids`) loads eagerly; the other sources start `NotAsked`.
fn base_model() -> client.Model {
  client.Model(
    page: client.ActivitiesListPage(client.default_filters()),
    translator: client.translator_for("sv"),
    activities: dict.new(),
    activities_ids: client.Loading,
    beach_bus_ids: client.NotAsked,
    climbing_wall_ids: client.NotAsked,
    favourited: client.NotAsked,
    details: dict.new(),
    statuses: dict.new(),
    spots: dict.new(),
    activity_tags: dict.new(),
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

pub fn prepend_id_adds_to_loaded_window_test() {
  assert client.prepend_id(client.Loaded([id_b()]), id_a())
    == client.Loaded([id_a(), id_b()])
}

pub fn prepend_id_dedupes_test() {
  assert client.prepend_id(client.Loaded([id_a()]), id_a())
    == client.Loaded([id_a()])
}

pub fn prepend_id_is_noop_unless_loaded_test() {
  assert client.prepend_id(client.NotAsked, id_a()) == client.NotAsked
  assert client.prepend_id(client.Loading, id_a()) == client.Loading
}

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
  assert client.apply_filters([a, b], client.default_filters()) == [a, b]
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
  assert client.apply_filters([climb, swim], filters) == [climb]
}

// LIST DERIVATION: tab_summaries -----------------------------------------------

pub fn tab_summaries_browse_maps_id_window_through_cache_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let summary_b = a_summary(id_b(), "B", None)
  let model_ =
    client.Model(
      ..base_model(),
      activities: dict.from_list([#(id_a(), summary_a), #(id_b(), summary_b)]),
      activities_ids: client.Loaded([id_a(), id_b()]),
    )
  assert client.tab_summaries(model_, client.TabActivities)
    == client.Loaded([summary_a, summary_b])
}

pub fn tab_summaries_browse_drops_uncached_ids_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let model_ =
    client.Model(
      ..base_model(),
      activities: dict.from_list([#(id_a(), summary_a)]),
      // id_b is in the window but not yet in the entity cache.
      activities_ids: client.Loaded([id_a(), id_b()]),
    )
  assert client.tab_summaries(model_, client.TabActivities)
    == client.Loaded([summary_a])
}

pub fn tab_summaries_browse_reflects_fetch_state_test() {
  assert client.tab_summaries(base_model(), client.TabBeachBus)
    == client.NotAsked
}

pub fn tab_summaries_favourites_derived_from_statuses_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let summary_b = a_summary(id_b(), "B", None)
  let booking = a_booking(id_c(), id_b())
  let model_ =
    client.Model(
      ..base_model(),
      activities: dict.from_list([#(id_a(), summary_a), #(id_b(), summary_b)]),
      statuses: dict.from_list([
        #(id_a(), model.Favourited),
        #(id_b(), model.Booked(booking)),
      ]),
      favourited: client.Loaded([]),
    )
  let assert client.Loaded(summaries) =
    client.tab_summaries(model_, client.TabFavourites)
  // dict key order is unspecified, so assert membership rather than order.
  assert list.length(summaries) == 2
  assert list.contains(summaries, summary_a)
  assert list.contains(summaries, summary_b)
}

pub fn tab_summaries_favourites_empty_reflects_fetch_state_test() {
  // Nothing favourited yet => mirror the favourited fetch state.
  assert client.tab_summaries(base_model(), client.TabFavourites)
    == client.NotAsked
  let loading = client.Model(..base_model(), favourited: client.Loading)
  assert client.tab_summaries(loading, client.TabFavourites) == client.Loading
}

// LIST SOURCES: source_remote / set_source_remote / ensure_source_loaded -------

pub fn set_then_get_source_remote_round_trips_test() {
  let model_ =
    client.set_source_remote(
      base_model(),
      client.SourceClimbingWall,
      client.Loaded([id_a()]),
    )
  assert client.source_remote(model_, client.SourceClimbingWall)
    == client.Loaded([id_a()])
}

pub fn ensure_source_loaded_marks_unasked_source_loading_test() {
  let #(next, _) =
    client.ensure_source_loaded(base_model(), client.SourceBeachBus)
  assert client.source_remote(next, client.SourceBeachBus) == client.Loading
}

pub fn ensure_source_loaded_leaves_loaded_source_untouched_test() {
  let model_ =
    client.Model(..base_model(), beach_bus_ids: client.Loaded([id_a()]))
  let #(next, _) = client.ensure_source_loaded(model_, client.SourceBeachBus)
  assert next.beach_bus_ids == client.Loaded([id_a()])
}

// ROUTING: uri_to_page ---------------------------------------------------------

pub fn uri_to_page_lists_activities_test() {
  let #(page, _) =
    client.uri_to_page(parse_uri("/_services/booking/activities"), dict.new())
  assert page == client.ActivitiesListPage(client.default_filters())
}

pub fn uri_to_page_new_activity_test() {
  let #(page, _) =
    client.uri_to_page(
      parse_uri("/_services/booking/activities/new"),
      dict.new(),
    )
  let assert client.ActivityNewPage(_, submit_error, _, _) = page
  assert submit_error == None
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

// UPDATE: favourite toggle (optimistic) ----------------------------------------

pub fn toggling_favourite_marks_unfavourited_as_favourited_test() {
  let #(next, _) =
    client.update(base_model(), client.UserToggledFavourite(id_a()))
  assert dict.get(next.statuses, id_a()) == Ok(model.Favourited)
}

pub fn toggling_favourite_invalidates_favourited_window_test() {
  let model_ = client.Model(..base_model(), favourited: client.Loaded([]))
  let #(next, _) = client.update(model_, client.UserToggledFavourite(id_a()))
  assert next.favourited == client.NotAsked
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
      favourited: client.Loaded([]),
    )
  let #(next, _) = client.update(model_, client.ApiCreatedBooking(Ok(booking)))
  assert dict.get(next.statuses, id_a()) == Ok(model.Booked(booking))
  assert next.favourited == client.NotAsked
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
      client.ApiReturnedActivityList(
        client.SourceBeachBus,
        Ok([summary_a, summary_b]),
      ),
    )
  assert next.beach_bus_ids == client.Loaded([id_a(), id_b()])
  assert dict.get(next.activities, id_a()) == Ok(summary_a)
  assert dict.get(next.activities, id_b()) == Ok(summary_b)
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
      client.ApiReturnedActivityList(client.SourceActivities, Ok([refreshed])),
    )
  assert dict.get(next.activities, id_a()) == Ok(refreshed)
  assert dict.get(next.details, id_a()) == Ok(client.Loaded(a_detail()))
}

pub fn failed_activity_list_marks_source_failed_test() {
  let #(next, _) =
    client.update(
      base_model(),
      client.ApiReturnedActivityList(
        client.SourceClimbingWall,
        Error(rsvp.BadBody),
      ),
    )
  let assert client.Failed(_) = next.climbing_wall_ids
}

pub fn created_activity_caches_and_invalidates_special_windows_test() {
  let model_ =
    client.Model(
      ..base_model(),
      activities_ids: client.Loaded([id_b()]),
      beach_bus_ids: client.Loaded([id_b()]),
      climbing_wall_ids: client.Loaded([id_b()]),
    )
  let activity = an_activity(id_a(), Some(5))
  let #(next, _) =
    client.update(model_, client.ApiCreatedActivity(Ok(activity)))
  assert next.activities_ids == client.Loaded([id_a(), id_b()])
  assert next.beach_bus_ids == client.NotAsked
  assert next.climbing_wall_ids == client.NotAsked
  // The summary lands in `activities`; only the detail-only fields in `details`.
  assert dict.get(next.activities, id_a())
    == Ok(a_summary(id_a(), "Climb", Some(5)))
  assert dict.get(next.details, id_a()) == Ok(client.Loaded(a_detail()))
}

pub fn deleted_activity_purges_caches_and_all_windows_test() {
  let summary_a = a_summary(id_a(), "A", None)
  let summary_b = a_summary(id_b(), "B", None)
  let model_ =
    client.Model(
      ..base_model(),
      activities: dict.from_list([#(id_a(), summary_a), #(id_b(), summary_b)]),
      activities_ids: client.Loaded([id_a(), id_b()]),
      beach_bus_ids: client.Loaded([id_a()]),
      statuses: dict.from_list([#(id_a(), model.Favourited)]),
    )
  let #(next, _) =
    client.update(model_, client.ApiDeletedActivity(id_a(), Ok(Nil)))
  assert next.activities_ids == client.Loaded([id_b()])
  assert next.beach_bus_ids == client.Loaded([])
  assert dict.has_key(next.activities, id_a()) == False
  assert dict.get(next.statuses, id_a()) == Error(Nil)
}

// UPDATE: list filters & tabs --------------------------------------------------

pub fn selecting_tab_updates_filter_and_lazily_loads_source_test() {
  // index 1 == TabBeachBus, whose source starts NotAsked in base_model.
  let #(next, _) = client.update(base_model(), client.UserSelectedTab(1))
  let assert client.ActivitiesListPage(filters) = next.page
  assert filters.tab == client.TabBeachBus
  assert next.beach_bus_ids == client.Loading
}

pub fn retrying_load_marks_current_tab_source_loading_test() {
  let model_ =
    client.Model(
      ..base_model(),
      activities_ids: client.Failed(client.LoadActivitiesFailed),
    )
  let #(next, _) = client.update(model_, client.UserClickedRetryLoad)
  assert next.activities_ids == client.Loading
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
