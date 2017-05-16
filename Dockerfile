# A minimal Nginx container including ContainerPilot
FROM nginx:1.13

# Add some stuff via apt-get
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bc \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Consul
# Releases at https://releases.hashicorp.com/consul
RUN export CONSUL_VERSION=0.7.3 \
    && export CONSUL_CHECKSUM=901a3796b645c3ce3853d5160080217a10ad8d9bd8356d0b73fcd6bc078b7f82 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Create empty directories for Consul config and data
RUN mkdir -p /etc/consul \
    && mkdir -p /var/lib/consul

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
RUN export CONSUL_TEMPLATE_VERSION=0.18.0 \
    && export CONSUL_TEMPLATE_CHECKSUM=f7adf1f879389e7f4e881d63ef3b84bce5bc6e073eb7a64940785d32c997bc4b \
    && curl --retry 7 --fail -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_CHECKSUM}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VER 2.7.2
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=e886899467ced6d7c76027d58c7f7554c2fb2bcc \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Add Dehydrated
RUN export DEHYDRATED_VERSION=v0.3.1 \
    && curl --retry 8 --fail -Lso /tmp/dehydrated.tar.gz "https://github.com/lukas2511/dehydrated/archive/${DEHYDRATED_VERSION}.tar.gz" \
    && tar xzf /tmp/dehydrated.tar.gz -C /tmp \
    && mv /tmp/dehydrated-0.3.1/dehydrated /usr/local/bin \
    && rm -rf /tmp/dehydrated-0.3.1

# Add jq
RUN export JQ_VERSION=1.5 \
    && curl --retry 8 --fail -Lso /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" \
    && chmod a+x /usr/local/bin/jq

# Add our configuration files and scripts
RUN rm -f /etc/nginx/conf.d/default.conf
COPY etc/acme /etc/acme
COPY etc/containerpilot.json /etc/
COPY etc/nginx /etc/nginx/templates
COPY bin /usr/local/bin

# Usable SSL certs written here
RUN mkdir -p /var/www/ssl
# Temporary/work space for keys
RUN mkdir -p /var/www/acme/ssl
# ACME challenge tokens written here
RUN mkdir -p /var/www/acme/challenge
# Consul session data written here
RUN mkdir -p /var/consul

CMD [ "/usr/local/bin/containerpilot", \
    "nginx", \
        "-g", \
        "daemon off;"]
