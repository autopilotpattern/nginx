# A minimal Nginx container including ContainerPilot and a simple virtualhost config
FROM nginx:latest

# Build-time metadata as defined at http://label-schema.org
# with added usage described in https://microbadger.com/#/labels
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.name="Autopilot Pattern Nginx" \
    org.label-schema.url="https://github.com/autopilotpattern/nginx" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/autopilotpattern/nginx"

# Add some stuff via apt-get
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bc \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Add Consul from https://releases.hashicorp.com/consul
RUN export CHECKSUM=abdf0e1856292468e2c9971420d73b805e93888e006c76324ae39416edcf0627 \
    && curl -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip" \
    && echo "${CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
RUN export CONSUL_TEMPLATE_VERSION=0.14.0 \
    && export CONSUL_TEMPLATE_CHECKSUM=7c70ea5f230a70c809333e75fdcff2f6f1e838f29cfb872e1420a63cdf7f3a78 \
    && curl --retry 7 --fail -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_CHECKSUM}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VER 2.3.0
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=ec9dbedaca9f4a7a50762f50768cbc42879c7208 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Add our configuration files and scripts
COPY etc /etc
COPY bin /usr/local/bin

CMD [ "/usr/local/bin/containerpilot", \
    "nginx", \
        "-g", \
        "daemon off;"]
