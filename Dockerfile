FROM php:fpm

COPY ./conf/php-custom.ini /usr/local/etc/php/conf.d/php-fpm-neos.ini
COPY ./conf/www.conf /usr/local/etc/php-fpm.d/www.conf

#Packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev \
    zip \
    libmagickwand-dev \
    git \
    git-core \
    mc

RUN pecl install \
    imagick \
    xdebug

#PHP Extensions
RUN    docker-php-ext-install pdo_mysql \
    && docker-php-ext-install tokenizer \
    && docker-php-ext-install mbstring \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-install zip\
    && docker-php-ext-enable imagick\
    && docker-php-ext-enable xdebug

#Enable XDebug Extension
RUN    echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini
RUN sed -i -e 's/listen.*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.conf
# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# Cleanup
RUN apt-get purge --auto-remove -y g++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Neos
WORKDIR /var/www/html
RUN composer create-project neos/neos-base-distribution ./

CMD ["php-fpm", "--allow-to-run-as-root"]