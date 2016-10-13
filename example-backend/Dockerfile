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
RUN export CONSUL_VERSION=0.7.0 \
    && export CONSUL_CHECKSUM=b350591af10d7d23514ebaa0565638539900cdb3aaa048f077217c4c46653dd8 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VER 2.4.3
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=2c469a0e79a7ac801f1c032c2515dd0278134790 \
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
