#!/bin/bash
cat $1 | grep -va https | sed "s/http/https/"| xargs -I{} grep -a {} $1 |sed "s/https/http/; s/\/\//\.\./" | xargs -I{} sed -i '/{}/d' $1
