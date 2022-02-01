#!/bin/bash

# How to download SVGs from https://azure.microsoft.com/en-us/patterns/styles/glyphs-icons/ since there is conveniently no zip or other batch download...
# You will likely need to sudo

# cd ~
mkdir azure-svgs
cd azure-svgs

curl https://azure.microsoft.com/en-us/patterns/styles/glyphs-icons/ > glyphs-icons.html

urls=$(grep -i -o "\/en-us\/patterns\/styles\/glyphs-icons\/[a-zA-Z0-9+-]*\.svg" glyphs-icons.html)

for url in $urls
do
    curl -O "https://azure.microsoft.com""$url"
done
