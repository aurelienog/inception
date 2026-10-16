FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY conf/default.conf /etc/nginx/sites-available/default
COPY html/ /var/www/website/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
