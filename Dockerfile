FROM php:7.0-apache

MAINTAINER Patrik Šíma <patrik@wrongware.cz>

#####################################
# System
#####################################
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y \
    libxml2-dev \
    libcurl4-openssl-dev \
    git \
    curl \
    vim \
    unzip \
    nodejs \
    npm \
    ruby \
    ruby-dev

#####################################
# NPM update
#####################################
RUN npm install -y -g npm
RUN ln -s "$(which nodejs)" /usr/bin/node

#####################################
# Gulp, compass
#####################################
RUN npm install -y --global gulp-cli
RUN gem update --system && \
    gem install compass

#####################################
# PHP
#####################################
RUN docker-php-ext-install soap
RUN docker-php-ext-configure mysqli && \
    docker-php-ext-install mysqli curl
RUN docker-php-ext-install zip

#####################################
# Apache
#####################################
ADD server.key /etc/ssl/certs/
ADD server.pem /etc/ssl/certs/

ADD 000-default.conf /etc/apache2/sites-available/
ADD default-ssl.conf /etc/apache2/sites-available/
# ADD adminer /usr/share/adminer
# ADD conf/adminer.conf /etc/apache2/conf-available/adminer.conf
# ADD conf/001-wrongware.conf /etc/apache2/sites-available/001-wrongware.conf
# ADD conf/apache2.conf /etc/apache2/apache2.conf
# ADD conf/php.ini /usr/local/etc/php/php.ini

RUN a2enmod access_compat alias auth_basic authn_core authn_file authz_core authz_host authz_user autoindex deflate dir env filter headers mime negotiation php7 rewrite setenvif status ssl
# RUN a2enconf adminer.conf
# RUN a2dissite 000-default
RUN a2ensite 000-default.conf
RUN a2ensite default-ssl.conf

#####################################
# Composer
#####################################
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/bin/composer
RUN composer self-update

#####################################
# WP-CLI
#####################################
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
RUN wp cli update --yes --allow-root

#####################################
# Non-Root User
#####################################
# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ARG PGID=1000
RUN groupadd -g $PGID wrongware && \
    useradd -u $PUID -g wrongware -m wrongware

#####################################
# Set Timezone
#####################################
ARG TZ=UTC
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Clean up
USER root
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set default work directory
WORKDIR /var/www/html

EXPOSE 80 443
