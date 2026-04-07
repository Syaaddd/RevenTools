#!/bin/bash
# Quick fix: Remove carriage returns from raven.sh
sed -i 's/\r$//' raven.sh
echo "Fixed line endings in raven.sh"
