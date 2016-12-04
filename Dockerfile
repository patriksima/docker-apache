FROM php:7.0-apache

MAINTAINER Patrik Šíma <patrik@wrongware.cz>

#####################################
# System
#####################################
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-utils \
    libxml2-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    git \
    curl \
    vim \
    unzip

#####################################
# NPM
#####################################
ARG INSTALL_NPM=true
ENV INSTALL_NPM ${INSTALL_NPM}
RUN if [ ${INSTALL_NPM} = true ]; then \
    apt-get install -y npm nodejs && \
    npm install -y -g npm && \
    ln -s "$(which nodejs)" /usr/bin/node \
;fi

#####################################
# Gulp (depends on NPM)
#####################################
ARG INSTALL_GULP=true
ENV INSTALL_GULP ${INSTALL_GULP}
RUN if [ ${INSTALL_GULP} = true ]; then \
    npm install -y --global gulp-cli \
;fi

#####################################
# Compass
#####################################
ARG INSTALL_COMPASS=true
ENV INSTALL_COMPASS ${INSTALL_COMPASS}
RUN if [ ${INSTALL_COMPASS} = true ]; then \
    apt-get install -y ruby ruby-dev && \
    gem update --system && \
    gem install compass \
;fi

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

RUN a2enmod access_compat alias auth_basic authn_core authn_file authz_core authz_host authz_user autoindex deflate dir env filter headers mime negotiation php7 rewrite setenvif status ssl
RUN a2ensite 000-default.conf
RUN a2ensite default-ssl.conf

#####################################
# Composer
#####################################
ARG INSTALL_COMPOSER=true
ENV INSTALL_COMPOSER ${INSTALL_COMPOSER}
RUN if [ ${INSTALL_COMPOSER} = true ]; then \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/bin/composer && \
    composer self-update \
;fi

#####################################
# WP-CLI
#####################################
ARG INSTALL_WPCLI=true
ENV INSTALL_WPCLI ${INSTALL_WPCLI}
RUN if [ ${INSTALL_WPCLI} = true ]; then \
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    wp cli update --yes --allow-root \
;fi

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
ARG TZ=Europe/Prague
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN printf "[Date]\ndate.timezone=$TZ" > /usr/local/etc/php/conf.d/timezone.ini

# Clean up
USER root
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set default work directory
WORKDIR /var/www/html

EXPOSE 80 443
