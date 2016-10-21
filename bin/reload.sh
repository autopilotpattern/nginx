#!/bin/bash
set -e

generate-config
nginx -s reload
