FROM debian:12

RUN apt-get update && \
    apt-get install -y mariadb-server gosu && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/mysql/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/init-mariadb.sh /usr/local/bin/init-mariadb.sh

RUN chmod +x /usr/local/bin/init-mariadb.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-mariadb.sh"]