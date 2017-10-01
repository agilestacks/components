#!/bin/bash -e

# Dirty ugly hack for inserting data into configmap :-( :-[ :-<
sso_url=$(cat okta/ssoUrl)
sed -i '' "s/#SAML_TARGET_URL#/https://$sso_url" values.yaml

fingerprint=$(openssl x509 -in okta/okta.pem -inform pem -noout -fingerprint)
sed -i '' "s/#SAML_CERT_FINGERPRINT#/$fingerprint" values.yaml


