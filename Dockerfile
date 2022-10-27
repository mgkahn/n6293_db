FROM mgkahn/firebird3:latest

LABEL maintainer="Michael.Kahn@cuanschutz.edu"

ENV PREFIX=/usr/local/firebird
ENV VOLUME=/firebird
ENV DEBIAN_FRONTEND noninteractive
ENV FBURL=https://github.com/FirebirdSQL/firebird/releases/download/v3.0.10/Firebird-3.0.10.33601-0.tar.bz2
ENV DBPATH=/firebird/data
ENV ISC_PASSWORD=nurs6293
ENV TZ=America/Denver
ENV NETWORK=n6293_net

VOLUME ["/firebird"]

EXPOSE 3050/tcp

COPY ./databases/* /tmp/databases/
COPY ./databases-restore/* /tmp/restore/
COPY ./etc/*  /tmp/etc/

COPY docker-entrypoint.sh ${PREFIX}/docker-entrypoint.sh
RUN chmod +x ${PREFIX}/docker-entrypoint.sh

COPY docker-healthcheck.sh ${PREFIX}/docker-healthcheck.sh
RUN chmod +x ${PREFIX}/docker-healthcheck.sh \
    && apt-get update \
    && apt-get -qy install netcat \
    && rm -rf /var/lib/apt/lists/*
HEALTHCHECK CMD ${PREFIX}/docker-healthcheck.sh || exit 1

ENTRYPOINT ["/usr/local/firebird/docker-entrypoint.sh"]

CMD ["firebird"]
