FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fpc \
        lazarus-ide \
        make \
        && rm -rf /var/lib/apt/lists/*

ENV FPCDIR=/usr/share/fpcsrc/3.2.2

WORKDIR /app

COPY . /app

RUN find . -name "*.ppu" -delete && \
    fpc -Tdarwin -Px86664 project1.lpr 2>&1 || true

CMD ["/app/project1"]