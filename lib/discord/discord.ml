open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Printf

module Http = struct
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

  let get    = request ~meth:`GET
  let post   = request ~meth:`POST
  let put    = request ~meth:`PUT
  let delete = request ~meth:`DELETE

  let drain_resp_body (_, body) = Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int
end

module SlashCommand = struct 
  type t = {
    name        : string;
    description : string;
  }
  [@@deriving yojson]

  open struct
    let global_url = sprintf "https://discord.com/api/v10/applications/%d/commands"
    let guild_url  = sprintf "https://discord.com/api/v10/applications/%d/guilds/%d/commands"

    let register ~url ~token ~(commands: t list) env =
      let headers = [
        "Content-type", "application/json";
        "Authorization", sprintf "Bot %s" token;
      ] in
      let body =
        `Fixed (Yojson.Safe.to_string (`List (List.map yojson_of_t commands)))
      in
      Eio.Switch.run @@ fun sw ->
      let response = Http.post ~headers ~body env ~sw url in
      let body =
        try response |> Http.drain_resp_body |> Yojson.Safe.from_string |> Option.some with _ -> None
      in
      (Cohttp.Response.status (fst response), body)
  end

  module Register = struct
    let global ~application_id           = register ~url:(global_url application_id)
    let guild  ~application_id ~guild_id = register ~url:(guild_url application_id guild_id)
  end

  let run _handlers = ()
end
