#!/usr/bin/env bash
set -euo pipefail
nft add table inet lfcs5
nft add chain inet lfcs5 input '{ type filter hook input priority 0; policy accept; }'
nft add rule inet lfcs5 input tcp dport 18305 accept
