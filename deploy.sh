#!/bin/bash

set -e -u

# Set the following environment variables:
# DEPLOY_USERNAME = Rackspace cloud username
# DEPLOY_API_KEY = Rackspace cloud API key
# DEPLOY_REGION = 3 char region code for where you're uploading (e.g., ORD)
# DEPLOY_CONTAINER = Container in Cloud Files where the image will go
# DEPLOY_CONTAINER_PREFIX = A directory prefix within your container
# DEPLOY_BRANCHES = regex of branches to deploy; leave blank for all
# DEPLOY_EXTENSIONS = whitespace-separated file of extensions to deploy; leave blank for "jar war zip"
# DEPLOY_FILES = whitespace-separated files to deploy; leave blank for $TRAVIS_BUILD_DIR/target/*.$extensions
# DEPLOY_SEG_BYTES   = Size, in bytes, used for each segment. 134217728 (128 MB) recommended
# DEPLOY_CONCURRENCY = Maximum number of parallel threads. 20 recommended

default_seg_bytes=134217728
default_concurrency=20
default_extensions="jar war zip"
default_source_dir=$TRAVIS_BUILD_DIR/target

if [ -z "${DEPLOY_USERNAME-}" ]; then
    echo "\$DEPLOY_USERNAME not specified; not deploying."
    exit 1
fi

if [ -z "${DEPLOY_API_KEY-}" ]; then
    echo "\$DEPLOY_API_KEY not specified; not deploying."
    exit 1
fi

if [ -z "${DEPLOY_REGION-}" ]; then
    echo "\$DEPLOY_REGION not specified; not deploying."
    exit 1
fi

if [ -z "${DEPLOY_API_KEY-}" ]; then
    echo "\$DEPLOY_API_KEY not specified; not deploying."
    exit 1
fi

if [[ -z "${DEPLOY_CONTAINER-}" ]]
then
    echo "\$DEPLOY_CONTAINER not specified; not deploying."
    exit 1
fi

DEPLOY_SEG_BYTES=${DEPLOY_SEG_BYTES:-$default_seg_bytes}
DEPLOY_CONCURRENCY=${DEPLOY_CONCURRENCY:-$default_concurrency}
DEPLOY_CONTAINER_PREFIX=${DEPLOY_CONTAINER_PREFIX:-}
DEPLOY_BRANCHES=${DEPLOY_BRANCHES:-}
DEPLOY_EXTENSIONS=${DEPLOY_EXTENSIONS:-$default_extensions}
DEPLOY_SOURCE_DIR=${DEPLOY_SOURCE_DIR:-$default_source_dir}

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]
then
    target_path=pull-request/$TRAVIS_PULL_REQUEST

elif [[ -z "$DEPLOY_BRANCHES" || "$TRAVIS_BRANCH" =~ "$DEPLOY_BRANCHES" ]]
then
    target_path=deploy/$TRAVIS_BRANCH/$TRAVIS_BUILD_NUMBER

else
    echo "Not deploying."
    exit

fi

discovered_files=""
for ext in ${DEPLOY_EXTENSIONS}
do
    discovered_files+=" $(ls $DEPLOY_SOURCE_DIR/*.${ext} 2>/dev/null || true)"
done

files=${DEPLOY_FILES:-$discovered_files}

if [[ -z "$files" ]]
then
    echo "Files not found; not deploying."
    exit 1
fi

target=builds/${DEPLOY_CONTAINER_PREFIX}${DEPLOY_CONTAINER_PREFIX:+/}$target_path/

pip install --upgrade --user swiftly
export PATH=~/.local/bin:$PATH

for file in $files
do
    swiftly \
        --auth-url=https://identity.api.rackspacecloud.com/v2.0 \
        --auth-user=$DEPLOY_USERNAME \
        --auth-key=$DEPLOY_API_KEY \
        --region=$DEPLOY_REGION \
        --concurrency=$DEPLOY_CONCURRENCY \
        put \
         --segment-size=s${DEPLOY_SEG_BYTES} \
         --input=$file \
        ${DEPLOY_CONTAINER}/$target
done