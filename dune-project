(lang dune 3.10)

(name yggdrasill)

(license MIT)

(maintainers "Yuki Tajiri <lmdexpr@gmail.com>")
(authors "Yuki Tajiri")
(source (github lmdexpr/yggdrasill))

(generate_opam_files true)

(package
  (name discord)
  (synopsis "Discord library")
  (depends
    (dune (>= 3.10))
    (ocaml (>= 5.1))
    eio
    tls-eio
    mirage-crypto-rng-eio
    cohttp-eio
    yojson
    ppx_yojson_conv
    logs
    ))

(package
  (name minio)
  (synopsis "MinIO library")
  (depends
    (dune (>= 3.10))
    (ocaml (>= 5.1))
    eio
    tls-eio
    mirage-crypto-rng-eio
    cohttp-eio
    yojson
    ppx_yojson_conv
    logs
    ))

(package
  (name elasticmq)
  (synopsis "ElasticMQ library")
  (depends
    (dune (>= 3.10))
    (ocaml (>= 5.1))
    eio
    tls-eio
    mirage-crypto-rng-eio
    cohttp-eio
    yojson
    ppx_yojson_conv
    logs
    ))

(package
  (name ratatoskr)
  (synopsis "Discord bot on yggdrasill")
  (depends
    (dune (>= 3.10))
    (ocaml (>= 5.1))
    eio
    tls-eio
    mirage-crypto-rng-eio
    cohttp-eio
    yojson
    ppx_yojson_conv
    logs
    discord
    ))

(package
  (name nidhoggr)
  (synopsis "Encoder on yggdrasill")
  (depends
    (dune (>= 3.10))
    (ocaml (>= 5.1))
    eio
    tls-eio
    mirage-crypto-rng-eio
    cohttp-eio
    yojson
    ppx_yojson_conv
    logs
    discord
    ))
