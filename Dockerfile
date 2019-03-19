FROM debian:jessie

EXPOSE 8000/tcp
EXPOSE 8002/tcp

ARG servername=Seafile
ARG domain=localhost
ARG email=seafile@local.host
ARG password=12345678

ENV DEBIAN_FRONTEND=noninteractive

# Setup
RUN apt-get update && \
    apt-get -y install python2.7 \
                       libpython2.7 \
                       python-setuptools \
                       python-ldap \
                       python-urllib3 \
                       sqlite3 \
                       python-requests \
                       python-imaging \
                       libmemcached-dev \
                       memcached \
                       supervisor \
                       build-essential \
                       python-dev \
                       libz-dev \
                       wget

ADD download-seafile.py /download-seafile.py
ADD seafile.sh /usr/bin/seafile
ADD seahub.sh /usr/bin/seahub
ADD supervisord.conf /etc/supervisor/supervisord.conf

RUN chmod +x /download-seafile.py && \
    chmod +x /usr/bin/seafile && \
    chmod +x /usr/bin/seahub

# Install python libraries
WORKDIR /tmp

## Install pylibmc
RUN wget https://github.com/lericson/pylibmc/archive/1.6.0.tar.gz && \
    tar xfz 1.6.0.tar.gz && \
    cd pylibmc-1.6.0 && \
    python setup.py install

## Install django-pylibmc
RUN wget https://github.com/django-pylibmc/django-pylibmc/archive/v0.6.1.tar.gz && \
    tar xfz v0.6.1.tar.gz && \
    cd django-pylibmc-0.6.1 && \
    python setup.py install

# Install Seafile
WORKDIR /opt/seafile
RUN python /download-seafile.py
RUN tar xfz seafile-server_*.tar.gz && \
    mkdir installed && \
    mv *.tar.gz installed && \
    cd seafile-server* && \
    printf "\n${servername}\n${domain}\n/opt/data/seafile\n\n\n\n" | bash "$(pwd)/setup-seafile.sh" && \
    bash "$(pwd)/seafile.sh" start && \
    printf  "${email}\n${password}\n${password}\n" | bash "$(pwd)/seahub.sh" start

RUN printf "CACHES = { \n\
    'default': { \n\
        'BACKEND': 'django_pylibmc.memcached.PyLibMCCache', \n\
        'LOCATION': '/var/run/memcached.sock', \n\
    }, \n\
    'locmem': { \n\
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache', \n\
    }, \n\
} \n\
COMPRESS_CACHE_BACKEND = 'locmem'" >> /opt/seafile/conf/seahub_settings.py

# Cleanup
RUN apt-get -y remove build-essential \
                      python-dev \
                      libz-dev \
                      wget && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* \
           /tmp/* \
           /var/tmp/* \
           /download-seafile.py

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
VOLUME [ "/opt/data" ]