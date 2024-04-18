# Run app in Docker Container

## Create Docker Image

In `src` folder run script to create the appropriate Docker image.

```bash
docker build --progress=plain -t ePeregrina-app .
```

## Run Docker Container

To run Docker container use a command like this.

```bash
docker run --rm -p 38888:8888 -it ePeregrina-app
```

To set shared folders use volumes so your app can always pointing the appropriate paths.

```bash
docker run -v ${PWD}/settings.json:/app/settings.json `
            -v ${PWD}/books:/shared/books `
            -v ${PWD}/comics:/shared/comics `
            --rm -p 38888:8888 -it ePeregrina-app
```

## Open app in Browser

http://localhost:38888/
