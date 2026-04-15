# ============================================
# Stage 1: Base — shared dependencies & app files
# ============================================
FROM php:8.1-apache-bookworm AS base

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev \
    zip \
    unzip \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libonig-dev \
    gettext \
    cron \
    curl \
    default-mysql-client \
    && docker-php-ext-install mysqli pdo pdo_mysql zip curl gettext simplexml \
    && docker-php-ext-enable mysqli \
    && a2enmod rewrite \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set recommended PHP settings
RUN { \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /var/log/apache2/php_errors.log'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'post_max_size = 100M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    echo 'memory_limit = 256M'; \
    } > /usr/local/etc/php/conf.d/sendy.ini

# Copy application files
COPY --chown=www-data:www-data . /var/www/html/

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html/uploads \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod 775 /var/www/html/uploads

# ============================================
# Stage 2: App — Apache web server
# ============================================
FROM base AS app

# Configure Apache
RUN { \
    echo '<Directory /var/www/html>'; \
    echo '    Options Indexes FollowSymLinks'; \
    echo '    AllowOverride All'; \
    echo '    Require all granted'; \
    echo '</Directory>'; \
    } > /etc/apache2/conf-available/sendy.conf \
    && a2enconf sendy

# Copy entrypoint script
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=10s \
  CMD curl -f http://localhost/login || exit 1

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]

# ============================================
# Stage 3: Cron — scheduled task runner
# ============================================
FROM base AS cron

# Copy entrypoint script
COPY docker/cron-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/cron-entrypoint.sh

ENTRYPOINT ["cron-entrypoint.sh"]
