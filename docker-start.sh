#!/bin/bash

crond -f & static-web-server --port 8081 --root /usr/src/app/public
