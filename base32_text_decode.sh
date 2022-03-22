#!/bin/sh
echo -n $@ | base32 -w0 -d
