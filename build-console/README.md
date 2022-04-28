# Build & Bootstrap of Console

## To build the containers

```./build.sh```

## To run

```
iid=$(cat iid)
dsock=/var/run/docker.sock
docker run -d --cidfile cid -v $dsock:$dsock -v $HOME:$HOME $iid
```

## To attach to container

```
cid=$(cat cid)
docker exec -ti $cid /usr/bin/zsh
```
