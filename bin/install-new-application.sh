#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
export COMPOSER_PROCESS_TIMEOUT=3600

APP_DIR=/var/www
[[ -d ${APP_DIR} ]] || mkdir -p ${APP_DIR}

function info {
    printf "\033[0;36m${1}\033[0m \n"
}
function note {
    printf "\033[0;33m${1}\033[0m \n"
}
function success {
    printf "\033[0;32m${1}\033[0m \n"
}
function warning {
    printf "\033[0;95m${1}\033[0m \n"
}
function error {
    printf "\033[0;31m${1}\033[0m \n"
    exit 1
}

mkdir -p /tmp/src
cd /tmp/src

if [[ ! -z ${SSH_PRIVATE_KEY} ]]; then
    mkdir ~/.ssh
    echo 'Host *' > ~/.ssh/config
    echo 'StrictHostKeyChecking no' >> ~/.ssh/config
    # Add private ssh key for git clone
    echo ${SSH_PRIVATE_KEY} | base64 -d > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    # Starting ssh agent
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
fi



# Fix for wrong file system check
sed -i -e "s/return \$fileLength == 255;/return \$fileLength > 200;/g" ${APP_DIR}/app/OroRequirements.php

# If is composer application
if [[ -f ${APP_DIR}/composer.json ]]; then
    if [[ ! -f ${APP_DIR}/composer.lock ]]; then
        composer update --no-interaction --lock -d ${APP_DIR} || error "Can't update lock file"
    fi
    composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader -d ${APP_DIR} || error "Can't install dependencies"
else
    error "${APP_DIR}/composer.json not found!"
fi

rm -rf /tmp/*
rm -rf ~/.ssh
rm -rf ~/.composer
