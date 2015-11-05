FROM combro2k/debian-debootstrap:8

MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

# Environment variables
ENV HOME "${APP_HOME}"
ENV INSTALL_LOG "/var/log/build.log"

# Add first the scripts to the container
ADD resources/bin/ /usr/local/bin/

# Run the installer script
RUN /bin/bash -l -c 'bash /usr/local/bin/setup.sh build'

# Add remaining resources
ADD resources/etc/ /etc/

# Run the last bits and clean up
RUN /bin/bash -l -c '/usr/local/bin/setup.sh post_install | tee -a ${INSTALL_LOG} > /dev/null 2>&1'

EXPOSE 80

CMD ["/usr/local/bin/run"]