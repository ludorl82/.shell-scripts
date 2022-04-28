# Build & Bootstrap of Console

## To build the containers

```./build.sh```

## To run

```
iid=$(cat iid)
dsock=/var/run/docker.sock
docker run -d -v $dsock:$dsock -v $HOME:$HOME $iid
```
