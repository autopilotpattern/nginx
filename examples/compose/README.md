### Hello world example

Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment. Then start everything:

```bash
docker-compose -p nginx up -d
```

The Nginx server will register with the Consul server. You can see its status there in the Consul web UI. If you're using Docker for Mac, you can open your browser to that with the following command:

```bash
open "http://localhost:8500/ui"
```

You can view the demo backend running behind Nginx by opening a browser to the Nginx instance:

```bash
open "http://localhost:8080/example"
```
