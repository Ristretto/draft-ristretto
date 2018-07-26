#!/usr/bin/env bash

set -e

mmark -xml2 -page draft-ristretto.md generated/draft-ristretto.xml
xml2rfc --text generated/draft-ristretto.xml
xml2rfc --html generated/draft-ristretto.xml
