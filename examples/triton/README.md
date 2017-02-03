### Hello world example

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent Triton CLI](https://www.joyent.com/blog/introducing-the-triton-command-line-tool) (`triton` replaces our old `sdc-*` CLI tools).
1. [Configure Docker and Docker Compose for use with Joyent.](https://docs.joyent.com/public-cloud/api-access/docker)

Check that everything is configured correctly by sourcing the `setup.sh` script into your shell. This will check that your environment is setup correctly and set a `TRITON_DC` and `TRITON_ACCOUNT` environment variable that will be used to inject the Consul hostname into the Nginx and backend containers, so we can take advantage of [Triton Container Name Service (CNS)](https://www.joyent.com/blog/introducing-triton-container-name-service).

```
$ . setup.sh
$ env | grep TRITON
TRITON_DC=us-sw-1
TRITON_ACCOUNT=0f06a3e0-aaaa-bbbb-cccc-dddd12345212
```

Start everything:

```bash
docker-compose -p nginx up -d
```

The Nginx server will register with the Consul server. You can see its status there in the Consul web UI. On a Mac, you can open your browser to that with the following command:

```bash
open "http://$(triton ip nginx_consul_1):8500/ui"
```

You can open the demo app that Nginx is proxying by opening a browser to the Nginx instance IP:

```bash
open "http://$(triton ip nginx_nginx_1)"
```
