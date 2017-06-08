Autopilot Pattern Nginx
=======================

*A re-usable Nginx base image implemented according to the [Autopilot Pattern](http://autopilotpattern.io/) for automatic discovery and configuration.*

[![DockerPulls](https://img.shields.io/docker/pulls/autopilotpattern/nginx.svg)](https://registry.hub.docker.com/u/autopilotpattern/nginx/)
[![DockerStars](https://img.shields.io/docker/stars/autopilotpattern/nginx.svg)](https://registry.hub.docker.com/u/autopilotpattern/nginx/)

### A reusable Nginx container image

The goal of this project is to create an Nginx image that can be reused across environments without having to rebuild the entire image. Configuration of Nginx is entirely via ContainerPilot `job` and `watch` handlers, which update the Nginx configuration on disk via `consul-template`.

### Running in your own project

Consult https://github.com/autopilotpattern/wordpress for example usage, or see the examples in the examples directory for deploying to Joyent's Triton Cloud or via Docker Compose.

### Configuring Let's Encrypt (ACME)

Setting the `ACME_DOMAIN` environment variable will enable Let's Encrypt within the image. The image will automatically acquire certificates for the given domain, and renew them over time. If you scale to multiple instances of Nginx, they will elect a leader who will be responsible for renewing the certificates.  Any challenge response tokens as well as acquired certificates will be replicated to all Nginx instances.

By default, this process will use the Let's Encrypt staging endpoint, so as not to impact your API limits. When ready for production, you must also set the `ACME_ENV` environment variable to `production`.

You must ensure the domain resolves to your Nginx containers so that they can respond to the ACME `http` challenges. Triton users may [refer to this document](https://docs.joyent.com/public-cloud/network/cns/faq#can-i-use-my-own-domain-name-with-triton-cns) for more information on how to ensure your domain resolves to your Triton containers.

An example of a Docker Compose manifest with Let's Encrypt enabled:

```yaml
services:
  nginx:
    image: autopilotpattern/nginx
    mem_limit: 512m
    restart: always
    environment:
      - CONSUL_AGENT=1
      - ACME_ENV=staging
      - ACME_DOMAIN
      - CONSUL=nginx-consul.svc.${TRITON_CNS_SEARCH_DOMAIN_PRIVATE}
    ports:
      - 80
      - 443
      - 9090
    labels:
      - triton.cns.services=nginx-frontend
    network_mode: bridge
```

### Examples

The `examples/` directory includes a manifest for deploying via Docker Compose to a local Docker environment and a manifest for deploying to Joyent's Triton Cloud. The `examples/backend` directory is a simple Node.js application that acts as a demonstration for registering backends and updating the Nginx configuration via watching Consul. You can build the example applications with `make build/examples`.

When deploying to Triton the manifest expects that the `TRITON_CNS_SEARCH_DOMAIN_PRIVATE` environment variable is set in order to bootstrap service discovery with Triton CNS. If you're using the [`triton-docker-cli`](https://github.com/joyent/triton-docker-cli) wrapper, this will set automatically.

### Testing

The `tests/` directory includes integration tests for both the Triton and Compose example stacks described above. Build the test runner by making sure you've pulled down the submodule with `git submodule update --init` and then `make build/tester`.

Running `make test/triton` will run the tests in a container locally but targeting Triton Cloud. To run those tests you'll need a Triton Cloud account with your Triton command line profile set up. The test rig will use the value of the `TRITON_PROFILE` environment variable to determine what data center to target.
