#!/bin/bash

file_url=$1
dest_path=$2

wget "$file_url" -O "$dest_path"

# Don't forget this if you're getting private key file for a bastion box, for example
# chmod 600 ~/.ssh/id_rsa
