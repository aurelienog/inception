FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends  \
        vsftpd \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY tools/setup-ftp.sh /usr/local/bin/setup-ftp.sh

RUN chmod 0755 /usr/local/bin/setup-ftp.sh

EXPOSE 21
EXPOSE 21100-21110

ENTRYPOINT ["/usr/local/bin/setup-ftp.sh"]