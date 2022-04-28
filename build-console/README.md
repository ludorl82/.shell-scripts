# Build & Bootstrap of Console

## To build the containers

```./build.sh```

## To run

```
cntnr=252d5fd79930
dsock=/var/run/docker.sock
docker run -d -v $dsock:$dsock -v $HOME:$HOME $cntnr
```
