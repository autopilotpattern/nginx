Autopilot Pattern Nginx
=======================

*A re-usable Nginx base image implemented according to the [Autopilot Pattern](http://autopilotpattern.io/) for automatic discovery and configuration.*

[![DockerPulls](https://img.shields.io/docker/pulls/autopilotpattern/nginx.svg)](https://registry.hub.docker.com/u/autopilotpattern/nginx/)
[![DockerStars](https://img.shields.io/docker/stars/autopilotpattern/nginx.svg)](https://registry.hub.docker.com/u/autopilotpattern/nginx/)

### A reusable Nginx container image

The goal of this project is to create an Nginx image that can be reused across environments without having to rebuild the entire image. Configuration of Nginx is entirely via ContainerPilot `preStart` or `onChange` handlers, which read the top-level Nginx configuration from either the `NGINX_CONF` environment variable or Consul.

### Running in your own project

Consult https://github.com/autopilotpattern/wordpress for example usage.

### Hello world example

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent Triton CLI](https://www.joyent.com/blog/introducing-the-triton-command-line-tool) (`triton` replaces our old `sdc-*` CLI tools).
1. [Configure Docker and Docker Compose for use with Joyent.](https://docs.joyent.com/public-cloud/api-access/docker)

Check that everything is configured correctly by running `./setup.sh`. This will check that your environment is setup correctly and will create an `_env` file that includes injecting an environment variable for the Consul hostname into the Nginx and App containers so we can take advantage of [Triton Container Name Service (CNS)](https://www.joyent.com/blog/introducing-triton-container-name-service).

Start everything:

```bash
docker-compose -p nginx up -d
```

The Nginx server will register with the Consul server named in the `_env` file. You can see its status there in the Consul web UI. On a Mac, you can open your browser to that with the following command:

```bash
open "http://$(triton ip nginx_consul_1):8500/ui"
```

You can open the demo app that Nginx is proxying by opening a browser to the Nginx instance IP:

```bash
open "http://$(triton ip nginx_nginx_1)/example"
```

### Configuring LetsEncrypt (ACME)

Setting the `ACME_DOMAIN` environment variable will enable LetsEncrypt within the image. The image will automatically acquire certificates for the given domain, and renew them over time. If you scale to multiple instances of Nginx, they will elect a leader who will be responsible for renewing the certificates.  Any challenge response tokens as well as acquired certificates will be replicated to all Nginx instances. 

By default, this process will use the LetsEncrypt staging endpoint, so as not to impact your api limits. When ready for production, you must also set the `ACME_ENV` environment variable to `production`. 

You must ensure the domain resolves to your Nginx containers so that they can respond to the ACME http challenges. Triton users may [refer to this document](https://docs.joyent.com/public-cloud/network/cns/faq#can-i-use-my-own-domain-name-with-triton-cns) for more information on how to insure your domain resolves to your Triton containers.

Example excerpt from `docker-compose.yml` with LetsEncrypt enabled:

```yaml
nginx:
    image: autopilotpattern/nginx
    restart: always
    mem_limit: 512m
    env_file: _env
    environment:
        - BACKEND=example
        - CONSUL_AGENT=1
        - ACME_ENV=staging
        - ACME_DOMAIN=example.com
    ports:
        - 80
        - 443
        - 9090
    labels:
        - triton.cns.services=nginx
```
