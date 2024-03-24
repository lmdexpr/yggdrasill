let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.Src.set_level Cohttp_eio.src (Some Debug)

let port, config = Config.load ()

let callback =
  Discord.callback ~config ~on_interaction:(fun _request -> Command.match_all)

let on_error ex = Logs.warn (fun f -> f "%a" Eio.Exn.pp ex)

let () =
  Logs.info (fun f -> f "Listening on port %d" port);
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let socket =
    Eio.Net.listen env#net ~sw ~backlog:128 ~reuse_addr:true
      (`Tcp (Eio.Net.Ipaddr.V4.loopback, port))
  in
  Cohttp_eio.Server.run socket ~on_error @@
  Cohttp_eio.Server.make ~callback ()
