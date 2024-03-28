let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.Src.set_level Cohttp_eio.src (Some Debug)

let port, ({ public_key } : Config.t) = Config.load ()

let callback _socket request body =
  let ok ~body = Cohttp.Response.make ~status:`OK (), body in
  let empty_response ~status = Cohttp.Response.make ~status (), Cohttp_eio.Body.of_string "" in
  match Http.Request.(meth request, resource request, has_body request) with
  | `POST, "/", `Yes -> 
    let headers  = Http.Request.headers request in
    let body     = Eio.Buf_read.(body |> of_flow ~max_size:max_int |> take_all) in
    let verified = 
      Option.is_some @@ Discord.verify_key ~public_key headers body 
    in
    if not verified then empty_response ~status:`Unauthorized
    else (
      let body = Discord.Interaction.Body.of_string body in
      match body.type_ with
      | PING                -> ok ~body:Discord.InteractionResponse.Body.(response_of_yojson pong)
      | APPLICATION_COMMAND -> Command.match_all body
      | _                   -> empty_response ~status:`Service_unavailable
    )
  | `POST, "/", _ -> empty_response ~status:`Bad_request
  | `POST,   _, _ -> empty_response ~status:`Not_found
  | _             -> empty_response ~status:`Method_not_allowed

let on_error ex = Logs.warn (fun f -> f "%a" Eio.Exn.pp ex)

let () =
  Logs.info (fun f -> f "Listening on port %d" port);
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let socket =
    Eio.Net.listen env#net ~sw ~backlog:128 ~reuse_addr:true
      (`Tcp (Eio.Net.Ipaddr.V4.any, port))
  in
  Cohttp_eio.Server.run socket ~on_error @@
  Cohttp_eio.Server.make ~callback ()
