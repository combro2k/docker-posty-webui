#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

export NVM_DIR="/opt/nvm"
export PATH="${PATH}:${NVM_DIR}/npm/bin"
export NODE_PATH="${NODE_PATH}:${NVM_DIR}/npm/lib/node_modules"

export DEBIAN_FRONTEND="noninteractive"

export PACKAGES=(
    'curl'
    'nginx'
)

pre_install()
{
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 2>&1 || return 1
    echo deb http://nginx.org/packages/mainline/debian jessie nginx > /etc/apt/sources.list.d/nginx-stable-jessie.list

    chmod +x /usr/local/bin/* || return 1

    mkdir -p /data/web /data/logs || return 1

    apt-get update 2>&1 || return 1
	apt-get install -yq ${PACKAGES[@]} 2>&1 || return 1

	return 0
}

install_node_nvm()
{
    curl --location --silent -S \
        https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 2>&1 || return 1

    # Add variables to the default nvm loader
    echo '' >> ${NVM_DIR}/nvm.sh || return 1
    echo '# Set default variables' >> ${NVM_DIR}/nvm.sh || return 1
    echo "export PATH=\${PATH}:\${NVM_DIR}/npm/bin" >> ${NVM_DIR}/nvm.sh || return 1
    echo "export NODE_PATH=\${NODE_PATH}:\${NVM_DIR}/npm/lib/node_modules" >> ${NVM_DIR}/nvm.sh || return 1

    eval load_nvm 2>&1 || return 1

    nvm install stable 2>&1 || return 1
    nvm alias default stable 2>&1 || return 1
    nvm use stable 2>&1 || return 1

    return 0
}

load_nvm()
{
    if [ -f ${NVM_DIR}/nvm.sh ]; then
        source "${NVM_DIR}/nvm.sh" 2>&1 || return 1
    else
        echo "Could not load NVM"
        return 1
    fi

    return 0
}

install_posty_webui() {
    eval load_nvm 2>&1 || return 1

    npm install -g bower grunt-cli

    curl --location --silent -S \
            https://github.com/posty/posty_webui/archive/v2.0.6.tar.gz | tar zx -C /data/web --strip-components=1 2>&1 || return 1

    cd /data/web 2>&1 || return 1

    npm install --save-dev \
        grunt \
        grunt-contrib-cssmin \
        grunt-contrib-yuidoc \
        grunt-contrib-concat \
        grunt-contrib-htmlmin \
        grunt-contrib-requirejs \
        grunt-sync \
        grunt-contrib-copy \
        grunt-contrib-uglify 2>&1 || return 1

    bower install 2>&1 || return 1

    return 0
}

post_install()
{
	apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt 2>&1 || return 1

	return 0
}

build()
{
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	tasks=(
	    'pre_install'
        'install_node_nvm'
        'install_posty_webui'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..." || exit 1
		${task} | tee -a "${INSTALL_LOG}" > /dev/null 2>&1 || exit 1
	done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1 || exit 1
		${task} 2>&1 || exit 1
	done
fi
