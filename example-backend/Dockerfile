# a Node.js application container including ContainerPilot
FROM gliderlabs/alpine:3.3

# install curl
RUN apk update && apk add \
        nodejs \
        curl \
    && rm -rf /var/cache/apk/*

# install the Express.js dependency
COPY package.json /opt/example/
RUN cd /opt/example && npm install

# add Containerpilot and its configuration
ENV CONTAINERPILOT_VER 2.1.0
ENV CONTAINERPILOT file:///etc/containerpilot.json
COPY containerpilot.json /etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=e7973bf036690b520b450c3a3e121fc7cd26f1a2 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# add our application
COPY example.js /opt/example/

EXPOSE 4000
CMD [ "containerpilot", \
      "node", \
      "/opt/example/example.js" \
]
