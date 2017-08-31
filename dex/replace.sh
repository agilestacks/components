#!/bin/bash -e

# Dirty ugly hack for inserting data into configmap :-(((((
sso_url=$(cat okta/ssoUrl)
sed -i '' '/ssoURL: /s#okta_sso_url#'$sso_url'#' configmap.yaml

