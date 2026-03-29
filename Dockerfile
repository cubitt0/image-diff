FROM php:8.3-fpm-alpine AS base

RUN apk add --no-cache nginx supervisor curl

RUN docker-php-ext-install opcache

COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/app.ini

WORKDIR /app

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy composer files first for layer caching
COPY composer.json ./
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction 2>/dev/null || true

# Copy application
COPY . .

# Now run install again with all files present
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Cache warmup
RUN php bin/console cache:warmup --env=prod 2>/dev/null || true

# Permissions
RUN chown -R www-data:www-data /app/var 2>/dev/null || mkdir -p /app/var && chown -R www-data:www-data /app/var

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
