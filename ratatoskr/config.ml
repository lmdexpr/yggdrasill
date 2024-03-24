type t = {
  public_key : string;
}

let load () =
  let port = ref 8080 in
  let public_key = ref "" in
  Arg.parse
    [ ("-p", Arg.Set_int port, " Listening port number(8080 by default)")
    ; ("-k", Arg.Set_string public_key, " Discord public key")
    ]
    ignore "Usage: ratatoskr [-p PORT] [-k PUBLIC_KEY]";
  !port, {
    public_key = !public_key 
  }
