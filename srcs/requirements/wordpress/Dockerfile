
FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        php-fpm \
        php-cli \
        php-mysql \
        php-curl \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        curl \
        ca-certificates \
        tar \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Download a fixed WordPress release
RUN curl -fsSL \
        https://wordpress.org/wordpress-7.1.3.tar.gz \
        -o /tmp/wordpress.tar.gz && \
    tar -xzf /tmp/wordpress.tar.gz -C /usr/src/ && \
    rm -f /tmp/wordpress.tar.gz

# Install a fixed WP-CLI release
RUN curl -fsSL \
        https://github.com/wp-cli/wp-cli/releases/download/v2.12.0/wp-cli-2.12.0.phar \
        -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp && \
    wp --info

# Configure PHP-FPM pool
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Prepare WordPress directories
RUN mkdir -p /var/www/html /run/php

# Copy initialization scripts
COPY tools/check-wordpress-config.sh /usr/local/bin/check-wordpress-config.sh
COPY tools/setup-wordpress.sh /usr/local/bin/setup-wordpress.sh

RUN chmod +x \
    /usr/local/bin/check-wordpress-config.sh \
    /usr/local/bin/setup-wordpress.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup-wordpress.sh"]
