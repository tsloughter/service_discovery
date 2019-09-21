#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR/..

push=false
target=all
registry=tsloughter

usage() {
    echo "Usage: $0 [-p] [-t {builder|releaser|runner|plt|all}] [-r <registry>]"
    echo
    echo "  -p  Enable pushing images to registry after build"
    echo "  -t  Target image to build (default: all)"
    echo "  -r  Registry to push images"
}

while getopts ":t:r:p" opt; do
    case ${opt} in
        p )
            push=true
            ;;
        t )
            target=$OPTARG
            ;;
        r )
            registry=$OPTARG
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
        \? )
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# must export this so experimental Dockerfile features work
export DOCKER_BUILDKIT=1

IMAGE=${registry}/service_discovery
BUILD_IMAGE=${IMAGE}:builder
RELEASER_IMAGE=${IMAGE}:releaser
PLT_IMAGE=${IMAGE}:plt

CHKSUM_CMD=${CHKSUM_CMD:-cksum}

CHKSUM=$(cat rebar.config rebar.lock | $CHKSUM_CMD | awk '{print $1}')
GIT_REF=$(git rev-parse HEAD) # or with --short
GIT_BRANCH=$(git symbolic-ref --short HEAD)



docker build --target $target --tag $image --cache-from=${IMAGE}:master \
       --cache-from=${IMAGE}:${GIT_BRANCH} \
       --cache-to=${IMAGE}:${GIT_BRANCH} \
       --build-arg BUILDKIT_INLINE_CACHE=true -f Dockerfile .

! $push || docker push $image


echo "Finished building ${IMAGE}:${GIT_REF}"
