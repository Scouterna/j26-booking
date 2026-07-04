import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/option.{None, Some}
import gleam/time/duration
import pog
import server/web
import wisp
import wisp/simulate
import youid/uuid
import ywt
import ywt/algorithm
import ywt/claim
import ywt/sign_key.{type SignKey}
import ywt/verify_key.{type VerifyKey}

const test_issuer = "https://id.test.j26.se/realms/jamboree26"

const test_user_id = "3ae85c94-5d76-4d43-ab18-a3521d9ed479"

/// The db connection is a value-level requirement of `Context` only; the
/// authentication code under test never queries it.
fn context_with_keys(keys: List(VerifyKey)) -> web.Context {
  web.Context(
    static_directory: "",
    db_connection: pog.named_connection(process.new_name("unused_db")),
    jwt_verify_keys: web.JWTVerifyKeys(test_issuer, keys),
    authentication_result: web.NotAuthenticated,
    dev_fallback_user: None,
  )
}

/// Payload mirroring a real Keycloak access token: unknown roles alongside a
/// modelled one, and ScoutID group paths in Keycloak's `/`-prefixed format.
fn keycloak_payload() -> List(#(String, Json)) {
  [
    // Set through the payload rather than claim.audience, which encodes only
    // its primary value as a plain string: Keycloak issues an array-valued
    // `aud` with the extra built-in `account` audience, and verification must
    // accept it as long as any entry matches.
    #("aud", json.array(["j26-booking", "account"], json.string)),
    #("sub", json.string(test_user_id)),
    #("name", json.string("Markus Test Ledare")),
    #(
      "resource_access",
      json.object([
        #(
          "j26-booking",
          json.object([
            #(
              "roles",
              json.array(
                ["bookings:self:create", "default-roles-jamboree26"],
                json.string,
              ),
            ),
          ]),
        ),
        #(
          "account",
          json.object([
            #("roles", json.array(["manage-account"], json.string)),
          ]),
        ),
      ]),
    ),
    #(
      "groups",
      json.array(
        ["/scoutnet/1386", "/j26-scoutid-sync/groups/1386", "/scoutnet"],
        json.string,
      ),
    ),
  ]
}

fn keycloak_claims() -> List(claim.Claim) {
  [
    claim.issuer(test_issuer, []),
    claim.expires_at(max_age: duration.minutes(5), leeway: duration.seconds(0)),
  ]
}

fn sign_token(
  key: SignKey,
  payload: List(#(String, Json)),
  claims: List(claim.Claim),
) -> String {
  ywt.encode(payload:, claims:, key:)
}

fn expected_user() -> web.User {
  let assert Ok(id) = uuid.from_string(test_user_id)
  web.User(
    id:,
    name: "Markus Test Ledare",
    roles: [web.BookingsSelfCreate],
    group_id: Some(1386),
  )
}

pub fn authenticate_with_bearer_header_test() {
  let key = ywt.generate_key(algorithm.rs256)
  let token = sign_token(key, keycloak_payload(), keycloak_claims())
  let ctx = context_with_keys([verify_key.derived(key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer " <> token)

  assert web.authenticate(request, ctx).authentication_result
    == web.Authenticated(expected_user())
}

pub fn authenticate_with_access_token_cookie_test() {
  let key = ywt.generate_key(algorithm.rs256)
  let token = sign_token(key, keycloak_payload(), keycloak_claims())
  let ctx = context_with_keys([verify_key.derived(key)])

  // The j26-auth cookie value is the raw JWT (no wisp-style base64), so it is
  // set directly on the cookie header rather than through simulate.cookie.
  let request =
    simulate.request(http.Get, "/")
    |> request.set_cookie("j26-auth_access-token", token)

  assert web.authenticate(request, ctx).authentication_result
    == web.Authenticated(expected_user())
}

pub fn authenticate_without_token_test() {
  let ctx = context_with_keys([])

  assert web.authenticate(simulate.request(http.Get, "/"), ctx).authentication_result
    == web.NotAuthenticated
}

pub fn authenticate_with_non_bearer_scheme_test() {
  let ctx = context_with_keys([])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Basic dXNlcjpwYXNz")

  assert web.authenticate(request, ctx).authentication_result
    == web.NotAuthenticated
}

pub fn authenticate_with_garbage_token_test() {
  let key = ywt.generate_key(algorithm.rs256)
  let ctx = context_with_keys([verify_key.derived(key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer not-a-jwt")

  assert web.authenticate(request, ctx).authentication_result
    == web.InvalidToken
}

pub fn authenticate_with_wrong_signing_key_test() {
  let signing_key = ywt.generate_key(algorithm.rs256)
  let other_key = ywt.generate_key(algorithm.rs256)
  let token = sign_token(signing_key, keycloak_payload(), keycloak_claims())
  let ctx = context_with_keys([verify_key.derived(other_key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer " <> token)

  assert web.authenticate(request, ctx).authentication_result
    == web.InvalidToken
}

pub fn authenticate_with_wrong_issuer_test() {
  let key = ywt.generate_key(algorithm.rs256)
  let claims = [
    claim.issuer("https://id.evil.example.com", []),
    claim.audience("j26-booking", []),
    claim.expires_at(max_age: duration.minutes(5), leeway: duration.seconds(0)),
  ]
  let token = sign_token(key, keycloak_payload(), claims)
  let ctx = context_with_keys([verify_key.derived(key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer " <> token)

  assert web.authenticate(request, ctx).authentication_result
    == web.InvalidToken
}

pub fn authenticate_with_wrong_audience_test() {
  let key = ywt.generate_key(algorithm.rs256)
  let claims = [
    claim.issuer(test_issuer, []),
    claim.audience("some-other-client", []),
    claim.expires_at(max_age: duration.minutes(5), leeway: duration.seconds(0)),
  ]
  let token = sign_token(key, keycloak_payload(), claims)
  let ctx = context_with_keys([verify_key.derived(key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer " <> token)

  assert web.authenticate(request, ctx).authentication_result
    == web.InvalidToken
}

pub fn authenticate_without_audience_test() {
  let key = ywt.generate_key(algorithm.rs256)
  // Passing claim.audience at verification makes `aud` required, so a token
  // lacking it entirely must be rejected.
  let payload = [
    #("sub", json.string(test_user_id)),
    #("name", json.string("Markus Test Ledare")),
  ]
  let token = sign_token(key, payload, keycloak_claims())
  let ctx = context_with_keys([verify_key.derived(key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer " <> token)

  assert web.authenticate(request, ctx).authentication_result
    == web.InvalidToken
}

pub fn authenticate_with_non_uuid_sub_test() {
  let key = ywt.generate_key(algorithm.rs256)
  let payload = [
    #("aud", json.array(["j26-booking", "account"], json.string)),
    #("sub", json.string("not-a-uuid")),
    #("name", json.string("Markus Test Ledare")),
  ]
  let token = sign_token(key, payload, keycloak_claims())
  let ctx = context_with_keys([verify_key.derived(key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer " <> token)

  assert web.authenticate(request, ctx).authentication_result
    == web.InvalidToken
}

pub fn authenticate_without_roles_and_groups_test() {
  let key = ywt.generate_key(algorithm.rs256)
  let payload = [
    #("aud", json.array(["j26-booking", "account"], json.string)),
    #("sub", json.string(test_user_id)),
    #("name", json.string("Markus Test Ledare")),
  ]
  let token = sign_token(key, payload, keycloak_claims())
  let ctx = context_with_keys([verify_key.derived(key)])

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer " <> token)

  let assert Ok(id) = uuid.from_string(test_user_id)
  assert web.authenticate(request, ctx).authentication_result
    == web.Authenticated(web.User(
      id:,
      name: "Markus Test Ledare",
      roles: [],
      group_id: None,
    ))
}

pub fn authenticate_dev_fallback_applies_without_token_test() {
  let fallback = expected_user()
  let ctx =
    web.Context(..context_with_keys([]), dev_fallback_user: Some(fallback))

  assert web.authenticate(simulate.request(http.Get, "/"), ctx).authentication_result
    == web.Authenticated(fallback)
}

pub fn authenticate_dev_fallback_does_not_mask_invalid_token_test() {
  let fallback = expected_user()
  let ctx =
    web.Context(..context_with_keys([]), dev_fallback_user: Some(fallback))

  let request =
    simulate.request(http.Get, "/")
    |> simulate.header("authorization", "Bearer not-a-jwt")

  assert web.authenticate(request, ctx).authentication_result
    == web.InvalidToken
}

pub fn string_to_role_test() {
  assert web.string_to_role("activities:manage") == Ok(web.ActivitiesManage)
  assert web.string_to_role("bookings:others:create")
    == Ok(web.BookingsOthersCreate)
  assert web.string_to_role("bookings:read") == Ok(web.BookingsRead)
  assert web.string_to_role("bookings:self:create")
    == Ok(web.BookingsSelfCreate)
  assert web.string_to_role("admin") == Ok(web.Admin)
  assert web.string_to_role("default-roles-jamboree26") == Error(Nil)
}

pub fn require_role_with_role_test() {
  let user = web.User(..expected_user(), roles: [web.BookingsSelfCreate])

  let response =
    web.require_role(user, web.BookingsSelfCreate, fn() { wisp.ok() })

  assert response.status == 200
}

pub fn require_role_without_role_test() {
  let user = web.User(..expected_user(), roles: [web.BookingsRead])

  let response =
    web.require_role(user, web.BookingsSelfCreate, fn() { wisp.ok() })

  assert response.status == 403
}

pub fn require_role_admin_implies_all_test() {
  let user = web.User(..expected_user(), roles: [web.Admin])

  let response =
    web.require_role(user, web.ActivitiesManage, fn() { wisp.ok() })

  assert response.status == 200
}
