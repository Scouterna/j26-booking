import client
import gleam/option.{None, Some}
import gleam/uri
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}

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

pub fn relative_url_handles_bare_path_test() {
  let u =
    uri.Uri(
      scheme: None,
      userinfo: None,
      host: None,
      port: None,
      path: "/activities",
      query: None,
      fragment: None,
    )
  assert client.relative_url(u) == "/activities"
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
