#!/bin/bash

docker run \
    -ti \
    --rm \
    -e 'POSTY_API_URL=http://localhost:9292' \
    -e 'POSTY_API_KEY=hash' \
    --name posty_webui \
    -p 8181:80 \
    combro2k/posty-webui:latest ${@}
