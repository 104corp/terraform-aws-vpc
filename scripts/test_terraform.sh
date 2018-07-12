#!/bin/bash
./terraform init -input=false

find . -type f -name \"*.tf\" -exec dirname {} \;|sort -u | while read m; do (terraform validate -check-variables=false \"$m\" && echo \"√ $m\") || exit 1 ; done

if [[ -n "$(terraform fmt -write=false)" ]]; then
  echo "Some terraform files need be formatted, run 'terraform fmt' to fix";
  exit 1;
fi