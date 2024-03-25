FROM ocaml/opam:alpine AS init-opam

RUN set -x && \
    : "Update and upgrade default packagee" && \
    sudo apk update && sudo apk upgrade && \
    sudo apk add libsodium-dev

FROM init-opam AS ocaml-app-base
COPY . .
ARG TARGET
RUN set -x && \
    : "Install related pacakges" && \
    opam-2.1 install . --deps-only --locked && \
    eval $(opam-2.1 env) && \
    : "Build applications" && \
    dune build $TARGET && \
    sudo cp ./_build/default/$TARGET/$TARGET.exe /usr/bin/$TARGET

FROM alpine AS ocaml-app

COPY --from=ocaml-app-base /usr/bin/$TARGET /home/app/$TARGET
RUN set -x && \
    : "Update and upgrade default packagee" && \
    apk update && apk upgrade && \
    apk add libsodium23 && \
    : "Create a user to execute application" && \
    adduser -D app && \
    : "Change owner to app" && \
    chown app:app /home/app/$TARGET

WORKDIR /home/app
USER app
ENTRYPOINT ["/home/app/$TARGET"]
