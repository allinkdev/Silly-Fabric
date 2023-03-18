#!/bin/sh

set -e

docker build silly-build-collector/ -t silly-build-collector
docker build silly-gradle-builder/ -t silly-gradle-builder