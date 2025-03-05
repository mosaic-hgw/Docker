#!/bin/bash
echo "  last updated               : $(stat -c '%.19y' $(ls -t /var/lib/dpkg/info/*.list | head -n 1))"
