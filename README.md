# Apache Docker container

NPM 3.10.9

Gulp  1.2.2

Compass 1.0.3

WP-CLI 0.25.0

```
docker build --tag=apache .
docker run -d -p 80:80 -p 443:443 -v "$PWD":/var/www/html apache
docker exec -it --user=wrongware container_id /bin/bash
```
