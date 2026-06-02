#!/usr/bin/env bash
set -euo pipefail
mkdir -p /usr/local/src/lfcs-hello-op1
tar -xzf /opt/lfcs-src/lfcs-hello-1.0.tar.gz -C /usr/local/src/lfcs-hello-op1 --strip-components=1
sed -i 's/echo lfcs-hello/echo LFCS-COMPILED-1/' /usr/local/src/lfcs-hello-op1/Makefile
make -C /usr/local/src/lfcs-hello-op1
install -m 0755 /usr/local/src/lfcs-hello-op1/lfcs-hello /usr/local/bin/lfcs-hello-op1
