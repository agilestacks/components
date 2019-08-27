#!/bin/bash

IMAGE='crazyrad/deephorizon'

docker build -t "${IMAGE}" .
docker push "${IMAGE}"
