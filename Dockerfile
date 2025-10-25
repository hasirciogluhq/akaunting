# Multi-stage build for Akaunting - Multi-platform support
FROM --platform=$BUILDPLATFORM php:8.1-fpm-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    curl-dev \
    libcurl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    oniguruma-dev \
    icu-dev \
    icu-libs \
    icu-data-full \
    libxml2-dev \
    zip \
    unzip \
    git \
    nodejs \
    npm \
    libwebp-dev \
    libxpm-dev \
    libavif-dev \
    python3 \
    make \
    g++

# Install PHP extensions with optimizations
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    dom \
    fileinfo \
    gd \
    intl \
    mbstring \
    pdo_mysql \
    xml \
    zip \
    && docker-php-ext-enable opcache

# Note: ctype, curl, json, openssl, tokenizer are built-in PHP extensions (not critical for Akaunting)

# Install Composer - Multi-platform support
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application code first (required for autoload helpers)
COPY . .

# Install PHP dependencies without running post-install scripts (they require database)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --no-scripts

# Run only essential Laravel setup commands (package:discover is required)
RUN php artisan package:discover --ansi || true

# Copy trusted proxy configuration (these files are now available after COPY . .)
COPY docker/trusted-proxy.php config/trusted-proxy.php
COPY docker/proxy-middleware.php app/Http/Middleware/TrustedProxyMiddleware.php
COPY docker/proxy-setup.sh docker/proxy-setup.sh

# Install Node.js dependencies and build assets with increased memory limit
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN npm install && npm run production

# Platform-specific optimizations
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ] || [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
    echo "ARM platform detected - optimizing for ARM"; \
    # ARM-specific optimizations can be added here
    fi

# Set proper permissions and optimize
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache \
    && chmod +x /var/www/html/docker/proxy-setup.sh \
    && mkdir -p /var/www/html/storage/logs \
    && chown -R www-data:www-data /var/www/html/storage/logs \
    && chmod -R 755 /var/www/html/storage/logs

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy PHP configuration
COPY docker/php.ini /usr/local/etc/php/php.ini

# Expose port
EXPOSE 80

# Start supervisor
CMD ["/bin/sh", "-c", "/var/www/html/docker/proxy-setup.sh && /usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
