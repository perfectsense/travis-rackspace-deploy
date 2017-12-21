# Rackspace Deploy Script

This script is used by [Travis CI](https://travis-ci.com/) to continuously deploy artifacts to a Rackspace container.

When Travis builds a push to your project (not a pull request), any files matching `target/*.{war,jar,zip}` will be uploaded to your container with the prefix `builds/$DEPLOY_BUCKET_PREFIX/deploy/$BRANCH/$BUILD_NUMBER/`. Pull requests will upload the same files with a prefix of `builds/$DEPLOY_BUCKET_PREFIX/pull-request/$PULL_REQUEST_NUMBER/`.

For example, the 36th push to the `master` branch will result in the following files being created in your `exampleco-ops` container:

```
builds/{optional:DEPLOY_CONTAINER_PREFIX}/deploy/master/36/exampleco-1.0-SNAPSHOT.war
builds/{optional:DEPLOY_CONTAINER_PREFIX}/deploy/master/36/exampleco-1.0-SNAPSHOT.zip
```

When the 15th pull request is created, the following files will be uploaded into your bucket:
```
builds/{optional:DEPLOY_CONTAINER_PREFIX}/pull-request/15/exampleco-1.0-SNAPSHOT.war
builds/{optional:DEPLOY_CONTAINER_PREFIX}/pull-request/15/exampleco-1.0-SNAPSHOT.zip
```

## Usage

Your .travis.yml should look something like this:

```yaml
language: java

jdk:
  - oraclejdk8

install: true

branches:
  only:
    - develop
    - master
    - /^release-.*$/

before_script:
  - mvn versions:set -DnewVersion='${project.version}'-$([ $TRAVIS_PULL_REQUEST == false ] && echo ${TRAVIS_COMMIT:0:8} || echo "PR"${TRAVIS_PULL_REQUEST})

env:
  global:
    - DEPLOY_SOURCE_DIR=$TRAVIS_BUILD_DIR/site/target # optional - if your war file is somewhere other than ./target

script:
  - MAVEN_OPTS='-Xmx2048m' mvn -B -Plibrary verify
  - git clone https://github.com/perfectsense/travis-rackspace-deploy.git && travis-rackspace-deploy/deploy.sh
```

Note that any of the above environment variables can be set in Travis, and do not need to be included in your .travis.yml. `DEPLOY_USERNAME`, `DEPLOY_API_KEY`, `DEPLOY_CONTAINER`, and `DEPLOY_REGION` should always be set to your Rackspace credentials as environment variables in Travis, not this file.