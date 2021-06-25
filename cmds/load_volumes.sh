#!/bin/bash
# Extract all docker volumes sent in parameters in a single tar file

for VOLUME_TAR in $@
do
    DIR_NAME=""
    if [ -z ${VOLUME_TAR##*.tar} ]; then
        if [ -f $VOLUME_TAR ]; then
            tar xf $VOLUME_TAR
            DIR_NAME=${VOLUME_TAR%".tar"}
        else
            echo "File not found: $VOLUME_TAR"
        fi
    else
        echo "Error: File must be tar archive: $VOLUME_TAR"
    fi
    cd $DIR_NAME
    for TAR_FILE in *.tar
    do
        if [ -z ${TAR_FILE##*.tar} ]; then
            if [ -f $TAR_FILE ]; then
                DOCKER_VOLUME=${TAR_FILE%".tar"}
                docker volume create $DOCKER_VOLUME && \
                    docker run --rm \
                        -v $DOCKER_VOLUME:/$DOCKER_VOLUME \
                        -v $(pwd)/$TAR_FILE:/$TAR_FILE \
                        alpine tar xf /$TAR_FILE
            else
                echo "File not found: $TAR_FILE"
            fi
        else
            echo "Error: File must be tar archive: $TAR_FILE"
        fi
    done
    cd ..
    if [ ! -z ${DIR_NAME} ]; then
        rm -rf $DIR_NAME
    fi
done
