FROM php:7.4-fpm

ENV container docker

RUN echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" \
    | tee -a /etc/apt/sources.list.d/caddy-fury.list \
	&& apt-get update -y \
    && apt-get install -y \
        net-tools vim zip unzip \
        caddy cron sudo procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"
ENV PHPREDIS_VERSION 3.0.0

# https://gist.github.com/giansalex/2776a4206666d940d014792ab4700d80
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
	    libicu-dev libonig-dev libwebp-dev libzip-dev libpng-dev \
		libfreetype6-dev libjpeg62-turbo-dev \
		libmagickwand-dev libssl-dev \
    && docker-php-ext-install gd \
	  && docker-php-ext-install bcmath \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install opcache \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install zip \
    && docker-php-ext-install fileinfo \
    # install redis ext
    && mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis \
	  && rm -rf /usr/src/php/ext/redis \
    # install Imagick
    && printf "\n" | pecl install imagick \
	  && docker-php-ext-enable imagick \
    # clean
    && apt-get remove libicu-dev libonig-dev icu-devtools -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/php-opocache-cfg.ini
