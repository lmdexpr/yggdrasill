open struct
  let ok = Http.Response.make ~status:`OK
  let make_response body =
    ok (),
    Discord.InteractionResponse.Body.yojson_of_t body
    |> Yojson.Safe.to_string
    |> Cohttp_eio.Body.of_string
end

type t = {
  name : string;
  description : string;
  handler : Discord.Interaction.Body.t -> Http.Response.t * Cohttp_eio.Body.t;
}

let to_yojson command = `Assoc [
  "name", `String command.name;
  "description", `String command.description;
]

let ping _ = make_response Discord.InteractionResponse.{
  type_ = CHANNEL_MESSAGE_WITH_SOURCE;
  data = Some { content = Some "Pong!"}; 
}
let ping = {
  name = "ping"; description = "reply Pong!"; handler = ping;
}

let all = [ ping ]

let all_yojson = `List (List.map to_yojson all)

let match_all (body: Discord.Interaction.Body.t) =
  all
  |> List.find_opt (fun command -> command.name = body.data.name)
  |> Option.map (fun command -> command.handler)
  |> Option.value ~default:(fun _ -> Http.Response.make ~status:`Not_found (), Cohttp_eio.Body.of_string "")
  |> fun handler -> handler body

