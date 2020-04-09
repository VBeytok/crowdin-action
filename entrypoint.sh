#!/bin/sh

set -e

printenv


crowdin $1

ls -al
