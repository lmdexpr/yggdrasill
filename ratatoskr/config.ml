type t = {
  public_key : string;
}

open struct
  let getenv ~default name =
    Sys.getenv_opt name |> Option.value ~default

  let getenv_exn name =
    match Sys.getenv_opt name with
    | Some x -> x
    | None   -> failwith (Printf.sprintf "Environment variable %s is not set" name) 
end

let load () =
  int_of_string @@ getenv ~default:"8080" "RATATOSKR_PORT",
  {
    public_key = getenv_exn "RATATOSKR_PUBLIC_KEY"
  }
