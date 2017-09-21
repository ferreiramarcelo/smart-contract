#!/bin/bash

echo "pragma solidity ^0.4.12;"

echo ""

# find . -not -type d | grep ".sol" | grep -vi "migrations" | while read -r file; do cat $file; echo "";  done | grep -v "import \"" | grep -v "pragma solidity"

cat "exchange-order.txt" | while read -r file; do cat $file; echo "";  done | grep -v "import \"" | grep -v "pragma solidity"
