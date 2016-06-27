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

# Add Consul from https://releases.hashicorp.com/consul
RUN export CHECKSUM=abdf0e1856292468e2c9971420d73b805e93888e006c76324ae39416edcf0627 \
    && curl -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip" \
    && echo "${CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VER 2.3.0
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=ec9dbedaca9f4a7a50762f50768cbc42879c7208 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# add our application and configuration
COPY example.js /opt/example/
COPY containerpilot.json /etc

EXPOSE 4000
CMD [ "/usr/local/bin/containerpilot", \
      "node", \
      "/opt/example/example.js" \
]
