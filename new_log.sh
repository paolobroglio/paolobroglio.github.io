#!/bin/bash
# save as 'new-devlog.sh'
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
FILENAME="_devlog/$DATE-$(echo $1 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g').md"

cat > "$FILENAME" << EOF
---
layout: post
title: "$1"
date: $DATE
---

EOF

echo "Created $FILENAME"