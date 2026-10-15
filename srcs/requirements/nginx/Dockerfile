FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl  \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=ES/ST=Bizkaia/L=Bilbao/O=42/OU=Inception/CN=aunoguei.42.fr" \
        -addext "subjectAltName=DNS:aunoguei.42.fr" && \
    chmod 600 /etc/nginx/ssl/nginx.key

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]