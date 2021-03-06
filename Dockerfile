FROM ubuntu:18.04
LABEL maintainer="Martin Thomson <martin.thomson@gmail.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates coreutils curl git make ssh libxml2-utils xsltproc \
    python3-minimal python3-lxml python3-pip python3-setuptools python3-wheel \
    mmark ruby ghostscript enscript\
 && rm -rf /var/lib/apt/lists/* \
 && apt-get autoremove -y && apt-get clean -y

ENV USER root
ENV LOGNAME $USER
ENV HOSTNAME $USER
ENV HOME /home/$USER
ENV SHELL /bin/bash

#RUN useradd -d "$HOME" -s "$SHELL" -m "$USER"
WORKDIR $HOME
USER $USER

ENV BINDIR $HOME/bin
RUN mkdir -p $BINDIR
ENV PATH $BINDIR:/usr/local/bin:/usr/bin:/bin

RUN set -e; tool_install() { \
      tool="$1";version="$2";sha="$3"; tmp=$(mktemp -t "${tool}XXXXX.tgz"); \
      curl -sSLf "https://tools.ietf.org/tools/${tool}/${tool}-${version}".tgz -o "$tmp"; \
      [ $(sha256sum -b "$tmp" | cut -d ' ' -f 1 -) = "$sha" ]; \
      target="${BINDIR:-~/.local/bin}/${tool}"; \
      tar xzfO "$tmp" "${tool}-${version}/${tool}" >"$target"; rm -f "$tmp"; \
      chmod 755 "$target"; }; \
    tool_install idnits 2.16.0 \
    5d9f49e528879e46aff03dcaf3e0ef438ab49d5e834543a741df57fcaeca1ddb && \
    tool_install rfcdiff 1.47 \
    75a9e83869885836c024a94f35128eaf292c6b9de3fd9d3361fbc62d46ec9f16

RUN pip3 install --user --compile xml2rfc && \
    ln -s $HOME/.local/bin/xml2rfc $BINDIR
RUN gem install --no-doc --user-install --bindir $BINDIR \
    certified kramdown-rfc2629 && \
    certified-update

ENV KRAMDOWN_REFCACHEDIR=$HOME/.cache/xml2rfc
RUN mkdir -p $KRAMDOWN_REFCACHEDIR

RUN GIT_REFERENCE=$HOME/git-reference; \
    git init $GIT_REFERENCE; \
    git -C $GIT_REFERENCE remote add i-d-template https://github.com/martinthomson/i-d-template; \
    git -C $GIT_REFERENCE remote add rfc2629xslt https://github.com/reschke/xml2rfc; \
    git -C $GIT_REFERENCE fetch --all
