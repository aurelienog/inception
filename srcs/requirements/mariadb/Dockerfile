FROM debian:12

RUN apt-get update && \
    apt-get install -y mariadb-server gosu && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/mysql/*

COPY tools/init-mariadb.sh /usr/local/bin/init-mariadb.sh

RUN chmod +x /usr/local/bin/init-mariadb.sh

ENTRYPOINT ["/usr/local/bin/init-mariadb.sh"]