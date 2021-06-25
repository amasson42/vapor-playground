#!/bin/bash
# Turn all docker volumes sent in parameters to a single tar file with the name of the first parameters

if [[ "$#" -lt 2 ]]; then
    echo "Usage: output [volumes, ...]"
    exit 1
fi

VOLUME_DIRNAME=$1

mkdir $VOLUME_DIRNAME
for DOCKER_VOLUME in "${@:2}"
do
    docker volume inspect $DOCKER_VOLUME && \
        docker run --rm \
            -v $DOCKER_VOLUME:/$DOCKER_VOLUME \
            -v $(pwd)/$VOLUME_DIRNAME:/hostdir \
            alpine tar czvf /hostdir/$DOCKER_VOLUME.tar /$DOCKER_VOLUME > /dev/null
done
tar czvf $VOLUME_DIRNAME.tar $VOLUME_DIRNAME
rm -fr $VOLUME_DIRNAME
