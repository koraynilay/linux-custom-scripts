#!/bin/sh
echo -n $@ | base64 -w0 -d
