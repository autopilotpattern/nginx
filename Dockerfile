# a minimal Nginx container including containerbuddy and a simple virtulhost config
FROM nginx:latest

# install curl
RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip && \
    rm -rf /var/lib/apt/lists/*

RUN curl -Lo /tmp/consul_template_0.11.0_linux_amd64.zip https://github.com/hashicorp/consul-template/releases/download/v0.11.0/consul_template_0.11.0_linux_amd64.zip && \
    unzip /tmp/consul_template_0.11.0_linux_amd64.zip && \
    mv consul-template /bin

# get Containerbuddy release
RUN export CB=containerbuddy-0.0.1-alpha &&\
    mkdir -p /opt/containerbuddy && \
    curl -Lo /tmp/${CB}.tar.gz \
    https://github.com/joyent/containerbuddy/releases/download/0.0.1-alpha/${CB}.tar.gz && \
	tar xzf /tmp/${CB}.tar.gz -C /tmp && \
    mv /tmp/build/containerbuddy /opt/containerbuddy/

# add our configuration files
COPY config/containerbuddy /opt/containerbuddy/
COPY config/nginx/conf.d /etc/nginx/conf.d/
