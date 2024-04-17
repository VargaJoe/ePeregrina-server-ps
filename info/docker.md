# Run app in Docker Container

## Create Docker Image

In `src` folder run script to create the appropriate docker image.

```bash
docker build --progress=plain -t pelegrina-app .
```

## Run Docker Container

To run Docker Container use a command like this.

```bash
docker run --rm -p 38888:8888 -it pelegrina-app
```

## Open app in Browser

http://localhost:38888/
