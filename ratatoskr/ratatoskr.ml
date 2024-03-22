let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.Src.set_level Cohttp_eio.src (Some Debug)

let handler _socket request _body =
  match Http.Request.resource request with
  | "/" -> (Http.Response.make (), Cohttp_eio.Body.of_string "Hello, world!")
  | _ ->
    (Http.Response.make ~status:`Not_found (), Cohttp_eio.Body.of_string "")

let log_warning ex = Logs.warn (fun f -> f "%a" Eio.Exn.pp ex)

let () =
  let port = ref 8080 in
  Arg.parse
    [ ("-p", Arg.Set_int port, " Listening port number(8080 by default)") ]
    ignore "An HTTP/1.1 server";
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let socket =
    Eio.Net.listen env#net ~sw ~backlog:128 ~reuse_addr:true
      (`Tcp (Eio.Net.Ipaddr.V4.loopback, !port))
  and server = Cohttp_eio.Server.make ~callback:handler () in
  Cohttp_eio.Server.run socket server ~on_error:log_warning
