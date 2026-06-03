#!/usr/bin/env bash
set -euo pipefail
nft add table inet lfcs4
nft add chain inet lfcs4 input '{ type filter hook input priority 0; policy accept; }'
nft add rule inet lfcs4 input tcp dport 18304 accept
