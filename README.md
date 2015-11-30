triton-nginx
==========

*An Nginx container for container-native deployment and automatic backend discovery.*

### A reusable Nginx container image

The goal of this project is to create an Nginx image that can be reused across environments without having to rebuild the entire image. Configuration of Nginx is entirely via Containerbuddy `onStart` or `onChange` handlers, which read the top-level Nginx configuration from either the `NGINX_CONF` environment variable or Consul.


### Running the example

In the `examples` directory is a demonstration showing how Containerbuddy is used to knit together the components of a simple application. In this application, an Nginx node acts as a reverse proxy for any number of upstream application nodes. The application nodes register themselves with Consul as they come online, and the Nginx application is configured with an `onStart` and `onChange` handler that uses `consul-template` to write out a new Nginx configuration file and then gracefully reloads the configuration as needed.

To try it yourself:

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent CloudAPI CLI tools](https://apidocs.joyent.com/cloudapi/#getting-started) (including the `smartdc` and `json` tools)
1. Have your CloudFlare API key handy.
1. [Configure Docker and Docker Compose for use with Joyent](https://docs.joyent.com/public-cloud/api-access/docker):

```bash
curl -O https://raw.githubusercontent.com/joyent/sdc-docker/master/tools/sdc-docker-setup.sh && chmod +x sdc-docker-setup.sh
./sdc-docker-setup.sh -k us-east-1.api.joyent.com <ACCOUNT> ~/.ssh/<PRIVATE_KEY_FILE>
```


At this point you can run the example on Triton:

```bash
./start.sh

```

or in your local Docker environment:

```bash
./start.sh -f local-compose.yml

```
