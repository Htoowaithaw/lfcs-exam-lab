#!/usr/bin/env bash
set -euo pipefail
mkdir -p /usr/local/src/lfcs-hello-op2
tar -xzf /opt/lfcs-src/lfcs-hello-1.0.tar.gz -C /usr/local/src/lfcs-hello-op2 --strip-components=1
sed -i 's/echo lfcs-hello/echo LFCS-COMPILED-2/' /usr/local/src/lfcs-hello-op2/Makefile
make -C /usr/local/src/lfcs-hello-op2
install -m 0755 /usr/local/src/lfcs-hello-op2/lfcs-hello /usr/local/bin/lfcs-hello-op2
