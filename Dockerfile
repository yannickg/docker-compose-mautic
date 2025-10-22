# Define the Mautic version as an argument
ARG MAUTIC_VERSION=5.2.8-apache

# Build stage:
FROM mautic/mautic:${MAUTIC_VERSION} AS build

# Install dependencies needed for Composer to run and rebuild assets:
# Install dependencies needed for Composer and Node.js
RUN apt-get update && apt-get install -y git curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Composer globally:
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

# Install any Mautic theme or plugin using Composer:
# Configure composer to allow dev versions and then install the theme
RUN COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_PROCESS_TIMEOUT=10000 /usr/local/bin/composer config minimum-stability dev
RUN COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_PROCESS_TIMEOUT=10000 /usr/local/bin/composer config prefer-stable true
RUN COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_PROCESS_TIMEOUT=10000 /usr/local/bin/composer require chimpino/theme-air:^1.0 --no-scripts --no-interaction --with-all-dependencies

# Fix console permissions and rebuild assets
RUN chmod +x bin/console
RUN npm ci && php bin/console mautic:assets:generate

# Production stage:
FROM mautic/mautic:${MAUTIC_VERSION}

# Copy the built assets and the Mautic installation from the build stage:
COPY --from=build --chown=www-data:www-data /var/www/html /var/www/html
