Autopilot Pattern Nginx
==========

*A re-usable Nginx base image implemented according to the [Autopilot Pattern](http://autopilotpattern.io/) for automatic discovery and configuration.*

[![DockerPulls](https://img.shields.io/docker/pulls/autopilotpattern/nginx.svg)](https://registry.hub.docker.com/u/autopilotpattern/nginx/)
[![DockerStars](https://img.shields.io/docker/stars/autopilotpattern/nginx.svg)](https://registry.hub.docker.com/u/autopilotpattern/nginx/)
[![ImageLayers](https://badge.imagelayers.io/autopilotpattern/nginx:latest.svg)](https://imagelayers.io/?images=autopilotpattern/nginx:latest)
[![Join the chat at https://gitter.im/autopilotpattern/general](https://badges.gitter.im/autopilotpattern/general.svg)](https://gitter.im/autopilotpattern/general)

### A reusable Nginx container image

The goal of this project is to create an Nginx image that can be reused across environments without having to rebuild the entire image. Configuration of Nginx is entirely via ContainerPilot `preStart` or `onChange` handlers, which read the top-level Nginx configuration from either the `NGINX_CONF` environment variable or Consul.

### Running in your own project

Consult https://github.com/autopilotpattern/wordpress for example usage.
