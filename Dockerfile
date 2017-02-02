FROM gliderlabs/alpine:3.4
MAINTAINER 'Jussi Heinonen<jussi.heinonen@ft.com>'

ADD sh/* /

RUN apk add -U py-pip && pip install --upgrade pip && \
    apk add python-dev py-boto bash curl  && \
    pip install --upgrade awscli requests

# Clean
RUN rm -rf /var/cache/apk/*

CMD /bin/bash
