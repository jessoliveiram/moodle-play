FROM php:8.3-apache

# Instala as dependências de sistema necessárias para as extensões do Moodle
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libpq-dev \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    zip \
    intl \
    xml \
    soap \
    opcache \
    pgsql \
    pdo_pgsql

# Configurações recomendadas do PHP para o Moodle
RUN { \
    echo 'max_execution_time = 300'; \
    echo 'memory_limit = 512M'; \
    echo 'post_max_size = 100M'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'max_input_vars = 5000'; \
} > /usr/local/etc/php/conf.d/moodle-custom.ini

RUN a2enmod rewrite
WORKDIR /var/www/html