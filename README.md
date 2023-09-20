<!-- Build the docker image -->
docker buildx build --platform linux/amd64,linux/arm64 --no-cache --push -t kong_service:v3.4.0 .

## Steps to use kong in Macs M1

```bash
<!-- Create a docker volume for kong-->
docker volume create kong_data

<!-- Import the data from the file to the docker db volume -->
docker run --rm -v /Users/roberto.rojas/Desktop/backup.tar.gz:/source -v kong_data:/target busybox sh -c "tar xzf /source -C /target"

<!-- create the container with the db for kong using the volume previously created-->
docker run --name kong_database -v kong_data:/var/lib/postgresql/data --network kong_network -p 5436:5436 -e POSTGRES_DB=kong -e POSTGRES_USER=kong -e POSTGRES_PASSWORD=kong postgres:12

<!-- Prepare db 
docker run --rm --network kong_network -e KONG_DATABASE=postgres -e KONG_PG_HOST=kong_database -e KONG_PG_PASSWORD=kong kong/kong-gateway:3.4.0.0 kong migrations bootstrap -->

<!-- Pull the kong image -->
docker pull --platform linux/arm64 robertovargas/kong_service:v3.4.0

<!-- Run the container -->
docker run --name kong_service --network kong_network -p 8000:8000 -p 8001:8001 -e KONG_DATABASE=postgres -e KONG_PG_HOST=kong_database -e KONG_PG_PASSWORD=kong -e KONG_ADMIN_LISTEN=0.0.0.0:8001 -it robertovargas/kong_service:v3.4.0 /bin/bash

<!-- Execute conainer -->
docker exec -it kong_service /bin/bash
    <!-- - kong start
    - kong migrations up
    - kong migrations finish -->
```