#!/bin/sh
_pre() {
	echo $1
}
_post() {
	echo $1
}
case $1 in
	pre)_pre $2;;
	post)_post $2;;
	*)echo echo;;
esac
