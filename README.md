# docker.haproxy

A flexible HAProxy Docker container that automatically reloads its backend nodes list when Docker Compose or Swarm is used to add and remove nodes of a specific service type and exposes the entire configuration file but with access to ENV vars for small dev/prod tweaks.

It also (conditionally) exposes the HAProxy stats GUI (http://domain:1936) and exposes a monitoring endpoint for an alert service to determine when all of the servers are down (http://domain:1937).

## Still to do:

 * SSL Termination support (waiting on Let's Encrypt).
 * Live reloading doesn't work as expected and "linking" is now deprecated although no functional replacement has been released. `/etc/hosts` isn't always reloaded on running containers so the backend nodes aren't automatically picked up when scaling. Work around is to scale down and back up the haproxy instance when scaling its backend: `docker-compose scale myapp=5 haproxy=0 haproxy=1`. This is obviously not ideal, but we'll have to wait until Docker includes proper service discovery to make it zero-downtime.... luckily we have all the pieces needed, just need notice and the info.
   * Related: https://github.com/docker/compose/pull/1375

### Why is this flexible?

The HAProxy configuration file is overridable, so you can fine tune any of the settings but the important part is that it uses a Jinja2 template, giving you access to ENV vars. This allows you to use the same _base_ settings in HAProxy for all your environments and tweak things for differences between dev and prod.

For example, if developing locally and watching your app's log stream, maybe you don't want HAProxy to run health checks on the nodes... otherwise your logs will be filled with HAProxy requests and be tough to read. You can set `HAPROXY_HEALTH_CHECK_NODES` to false.

Another example: keeping the HAProxy stats authentication name and password in ENV vars so they don't have to be hardcoded into the config.

The number of ENV vars that affect the configuration file is minimal because the idea is to keep dev/prod parity.

## How to Use:

You can use in a docker-compose block without having to do anything too fancy:

```yaml
haproxy:
  image: brite/haproxy:latest
  links:
    - myapp
  ports:
    - "80:80"
  environment:
    - HAPROXY_SERVICE_NAME_TO_PROXY=myapp

myapp:
  image: your_name/you_app:latest

```

Link HAProxy to the service you want to load balance and set that service's name in the environment variable. Now, running:

```bash
docker-compose scale haproxy=1 myapp=5
```

Will automatically update haproxy to distribute traffic between all the nodes for that service.

### Configuration file

If you want to fine tune the configuration file, you should override the template file, make a copy of [haproxy.cfg.j2](haproxy.cfg.j2) and edit as you like.  Then set the volume so your version of the config overrides the included one:

```yaml
haproxy:
  image: brite/haproxy:latest
  links:
    - myapp
  ports:
    - "80:80"
  environment:
    - HAPROXY_SERVICE_NAME_TO_PROXY=myapp
  volumes:
    - /your/path/haproxy.cfg.j2:/haproxy.cfg.j2
```

Now your configuration file will be compiled automatically when docker-compose adjusts nodes.

_Note:_ Do not put `daemon` into your config file, this will cause the container to stop immediately since HAProxy is backgrounded.

### ENV Vars

Required:
 * `HAPROXY_SERVICE_NAME_TO_PROXY` - Which of the linked services in your docker compose file should HAProxy load balance between.

Optional:
 * `HAPROXY_HEALTH_CHECK_NODES` - Default: `true` - Whether HAProxy will check the health of backend nodes.
 * `HAPROXY_STATS_ENABLED` - Default: `false` - Enable the HAProxy stats interface.
 * `HAPROXY_STATS_LOGIN` - Default: `admin:docker` - If stats interface is enabled, what username and password are required to Basic Auth to it.
