#!/usr/bin/env bash
set -euo pipefail
nft add table inet lfcs6
nft add chain inet lfcs6 input '{ type filter hook input priority 0; policy accept; }'
nft add rule inet lfcs6 input tcp dport 18306 accept
