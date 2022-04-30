# Build & Bootstrap of Console

## To build the containers

```./build.sh```

## To run

```
iid=$(cat tmp/iid-console)
dsock=/var/run/docker.sock
docker run -d --cidfile tmp/cid-console -v $dsock:$dsock -v $HOME:$HOME $iid
```

## To attach to container

```
cid=$(cat tmp/cid-console)
docker exec -e TMUX=$TMUX -e TMUX_DISPLAY=$TMUX_DISPLAY -e WINDOW=$WINDOW -e ENV=$ENV -ti $cid /usr/bin/zsh
```
