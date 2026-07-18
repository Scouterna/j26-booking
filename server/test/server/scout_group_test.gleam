import gleam/list
import server/scout_group

/// The registered-kår list serves `/api/scout-groups`; guard against the
/// export snapshot being truncated by a regeneration.
pub fn groups_carries_the_full_export_test() {
  assert list.length(scout_group.groups) == 621
}

/// A representative registered kår resolves to its name.
pub fn known_group_id_resolves_test() {
  assert scout_group.group_id_to_name(1102) == "Adolf Fredriks Scoutkår"
}

/// Kårnummer 16007 is claimed by two rows in the export; we resolve it to the
/// Blekinge kår (see the module note). This locks that decision in.
pub fn collision_resolves_to_jamshog_test() {
  assert scout_group.group_id_to_name(16_007) == "Jämshögs scoutkår"
}

/// An id not among the registered kårer falls back to a "Kår <id>" label
/// rather than failing — a token can carry a group not in the export.
pub fn unknown_group_id_falls_back_test() {
  assert scout_group.group_id_to_name(1386) == "Kår 1386"
}
