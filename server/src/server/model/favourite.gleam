import gleam/json.{type Json}
import server/sql
import shared/model.{type Favourite, Favourite}
import youid/uuid

pub fn from_create_favourite_row(row: sql.CreateFavouriteRow) -> Favourite {
  Favourite(id: row.id, user_id: row.user_id, activity_id: row.activity_id)
}

pub fn from_get_favourites_by_user_row(
  row: sql.GetFavouritesByUserRow,
) -> Favourite {
  Favourite(id: row.id, user_id: row.user_id, activity_id: row.activity_id)
}

pub fn to_json(favourite: Favourite) -> Json {
  let Favourite(id:, user_id:, activity_id:) = favourite
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("user_id", user_id |> uuid.to_string |> json.string),
    #("activity_id", activity_id |> uuid.to_string |> json.string),
  ])
}
