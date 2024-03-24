open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Printf

module Register = struct 
  open struct
    let null_auth ?ip:_ ~host:_ _ = Ok None

    let https ~authenticator =
      let tls_config = Tls.Config.client ~authenticator () in
      fun uri raw ->
      let host =
        Uri.host uri
        |> Option.map (fun x -> Domain_name.(host_exn (of_string_exn x)))
      in
      Tls_eio.client_of_flow ?host tls_config raw

    let request ?headers ?body ~meth env ~sw (url : string) =
      let headers = headers |> Option.map Cohttp.Header.of_list in
      let body =
        body
        |> Option.map (function `Fixed src -> Cohttp_eio.Body.of_string src)
      in
      let client =
        Cohttp_eio.Client.make
          ~https:(Some (https ~authenticator:null_auth))
          (Eio.Stdenv.net env)
      in
      Cohttp_eio.Client.call ~sw ?headers ?body client meth (Uri.of_string url)

    let body_to_yojson body = 
      try
        Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int
        |> Yojson.Safe.from_string
        |> Option.some
      with _ -> None
  end

  open struct
    let global_url = sprintf "https://discord.com/api/v10/applications/%d/commands"
    let guild_url  = sprintf "https://discord.com/api/v10/applications/%d/guilds/%d/commands"

    let register ~url ~token ~commands env =
      let headers = [
        "Content-type", "application/json";
        "Authorization", sprintf "Bot %s" token;
      ] in
      let body = `Fixed (Yojson.Safe.to_string commands) in
      Eio.Switch.run @@ fun sw ->
      let code, body = request ~meth:`POST ~headers ~body env ~sw url in
      (Cohttp.Response.status code, body_to_yojson body)
  end

  let global ~application_id           = register ~url:(global_url application_id)
  let guild  ~application_id ~guild_id = register ~url:(guild_url application_id guild_id)
end

module Interaction = struct
  type type_ =
    | PING
    | APPLICATION_COMMAND
    | MESSAGE_COMPONENT
    | APPLICATION_COMMAND_AUTOCOMPLETE
    | MODAL_SUBMIT

  let yojson_of_type_ = function
    | PING                             -> `Int 1
    | APPLICATION_COMMAND              -> `Int 2
    | MESSAGE_COMPONENT                -> `Int 3
    | APPLICATION_COMMAND_AUTOCOMPLETE -> `Int 4
    | MODAL_SUBMIT                     -> `Int 5

  let type__of_yojson = function
    | `Int 1 -> PING
    | `Int 2 -> APPLICATION_COMMAND
    | `Int 3 -> MESSAGE_COMPONENT
    | `Int 4 -> APPLICATION_COMMAND_AUTOCOMPLETE
    | `Int 5 -> MODAL_SUBMIT
    | _      -> raise (Yojson.Json_error "Invalid interaction type")

  module Body = struct
    type option = {
      name: string;
      value: string;
    } [@@deriving yojson]

    type data = {
      id: string;
      name: string;
      options: option list [@default []];
    } [@@deriving yojson]

    type t = {
      id: string;
      data: data;
      token: string;
      type_: type_;
      version: int;
    } [@@deriving yojson]

    let of_string s = s |> Yojson.Safe.from_string |> t_of_yojson
  end
end

module InteractionResponse = struct
  type type_ =
    | PONG
    | CHANNEL_MESSAGE_WITH_SOURCE
    | DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE
    | DEFERRED_UPDATE_MESSAGE
    | UPDATE_MESSAGE
    | APPLICATION_COMMAND_AUTOCOMPLETE_RESULT
    | MODAL
    | PREMIUM_REQUIRED

  let yojson_of_type_ = function
    | PONG                                    -> `Int 1
    | CHANNEL_MESSAGE_WITH_SOURCE             -> `Int 4
    | DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE    -> `Int 5
    | DEFERRED_UPDATE_MESSAGE                 -> `Int 6
    | UPDATE_MESSAGE                          -> `Int 7
    | APPLICATION_COMMAND_AUTOCOMPLETE_RESULT -> `Int 8
    | MODAL                                   -> `Int 9
    | PREMIUM_REQUIRED                        -> `Int 10

  let type__of_yojson = function
    | `Int 1  -> PONG
    | `Int 4  -> CHANNEL_MESSAGE_WITH_SOURCE
    | `Int 5  -> DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE
    | `Int 6  -> DEFERRED_UPDATE_MESSAGE
    | `Int 7  -> UPDATE_MESSAGE
    | `Int 8  -> APPLICATION_COMMAND_AUTOCOMPLETE_RESULT
    | `Int 9  -> MODAL
    | `Int 10 -> PREMIUM_REQUIRED
    | _       -> raise (Yojson.Json_error "Invalid interaction response type")

  module Body = struct
    type data = {
      content: string option [@default None];
    } [@@deriving yojson]

    type t = {
      type_: type_;
      data: data option [@default None];
    } [@@deriving yojson]

    let pong = { type_ = PONG; data = None }
    let channel_message_with_source content = { type_ = CHANNEL_MESSAGE_WITH_SOURCE; data = Some { content } }

    let response_of_yojson body = yojson_of_t body |> Yojson.Safe.to_string |> Cohttp_eio.Body.of_string
  end
end

open struct
  let verify_key ~public_key headers body =
    let (let*) = Option.bind in
    let* signature = Cohttp.Header.get headers "x-signature-ed25519" in
    let* timestamp = Cohttp.Header.get headers "x-signature-timestamp" in
    try
      Sodium.Auth.Bytes.(verify
        (Bytes.of_string (timestamp ^ body) |> to_key)
        (Bytes.of_string signature |> to_auth)
        (Bytes.of_string public_key)
      );
      Some ()
    with _ -> None

  let empty_response ~status = Cohttp.Response.make ~status (), Cohttp_eio.Body.of_string ""
  let pong () = Cohttp.Response.make ~status:`OK (), InteractionResponse.Body.(response_of_yojson pong)
end

let callback ~config:({ public_key }: Config.t) ~on_interaction _socket request body =
  if Http.Request.resource request = "/" then
    let headers = Http.Request.headers request in
    let body    = Eio.Buf_read.(of_flow ~max_size:max_int body |> take_all) in
    match verify_key ~public_key headers body with
    | None    -> empty_response ~status:`Unauthorized
    | Some () -> 
      let body = Interaction.Body.of_string body in
      match body.type_ with
      | PING                -> pong ()
      | APPLICATION_COMMAND -> on_interaction request body
      | _                   -> empty_response ~status:`Not_found
  else
    empty_response ~status:`Not_found

