# dart-testing monorepo

## Docker support

For each project in the monorepo, there needs to be a Dockerfile and service added
to the docker-compose.yml file.

Currently, we only have presence (microservice) so we can use docker-compose:

```# docker-compose build```

```# docker-compose build presence```

```# docker-compose up presence```

```# docker-compose up```
