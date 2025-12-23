import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import youid/uuid.{type Uuid}

pub type Activity {
  Activity(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
  )
}
