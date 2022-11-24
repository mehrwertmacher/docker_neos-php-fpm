FROM php:7.4-fpm-alpine

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG NAME
ARG PHP_REDIS_VERION="5.3.7"
ARG PHP_YAML_VERION="2.2.2"

ENV COMPOSER_VERSION 2.4.4
ENV COMPOSER_HOME /composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV PATH /composer/vendor/bin:$PATH

# Basic build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.license="MIT" \
      org.label-schema.name=$NAME \
      org.label-schema.url="https://github.com/mehrwertmacher/docker_neos-php-fpm" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/mehrwertmacher/docker_neos-php-fpm.git" \
      org.label-schema.vcs-type="Git"

# Install Packages
RUN set -x \
    && apk --update add tar curl openssl sed libzip-dev libuuid postgresql-dev icu-dev icu-data-full curl-dev libxml2-dev openldap-dev libpng libjpeg-turbo yaml libuuid git mc gettext oniguruma-dev \
    && apk add --virtual .phpize-deps $PHPIZE_DEPS imagemagick-dev libtool freetype-dev libpng-dev libjpeg-turbo-dev yaml-dev

RUN docker-php-ext-install \
      pdo_mysql \
      mbstring \
      opcache \
      json \
      zip \
      tokenizer \
      xml \
      sockets

RUN pecl install imagick xdebug redis-${PHP_REDIS_VERION} yaml-${PHP_YAML_VERION} uuid

RUN docker-php-ext-enable  \
      redis \
      yaml \
      uuid \
      xdebug \
      imagick

RUN apk add --virtual .imagick-runtime-deps imagemagick \
    && apk del .phpize-deps

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}  \
    && rm -rf /tmp/composer-setup.php \
    && composer --version

# set timezone
RUN apk add tzdata
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN echo "Europe/Berlin" > /etc/timezone
RUN apk del tzdata

RUN rm -rf /var/cache/apk/*

# Configure PHP
COPY ./conf/*.ini $PHP_INI_DIR/conf.d/
