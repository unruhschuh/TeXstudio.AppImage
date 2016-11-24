#!/bin/bash
docker run -it -v $(pwd):/build --rm centos:6.7 /bin/bash -c "cd /build; time ./recipe.sh"
