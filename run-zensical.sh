#!/usr/bin/env bash
set -euo pipefail

docker run --rm -it -p 8000:8000 -v "${PWD}:/docs" zensical/zensical
