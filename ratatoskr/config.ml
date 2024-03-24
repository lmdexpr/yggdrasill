type t = {
  public_key : string;
}

open struct
  let c x _ = x

  let getenv
    ?(default = fun name -> failwith (Printf.sprintf "Environment variable %s is not set" name)) 
    name =
    Sys.getenv_opt name |> Option.value ~default:(default name)
end

let load () =
  int_of_string @@ getenv ~default:(c "8080") "RATATOSKR_PORT",
  {
    public_key = getenv "RATATOSKR_PUBLIC_KEY"
  }
