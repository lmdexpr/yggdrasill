(lang dune 3.7)

(name yggdrasill)

(generate_opam_files true)

(source (github lmdexpr/yggdrasill))

(authors "Yuki Tajiri")

(maintainers "Yuki Tajiri <lmdexpr@gmail.com>")

(license MIT)

(package
 (name yggdrasill)
 (synopsis "Custom applications on yggdrasill (my server)")
 (allow_empty)
 (depends
   (ocaml (>= 5.1.0))
   (eio_main (>= 0.12))
   tls-eio
   alcotest
   ;cohttp
   ;cohttp-eio
   ;sodium
   ;discord
   ocamlformat
   ocaml-lsp-server
   dune)
)
