#!/bin/sh

docker build -t sjkaliski/infer-lambda .
docker run sjkaliski/infer-lambda
ID=$(docker ps --latest --quiet)
docker cp $ID:/build.zip deployment.zip
