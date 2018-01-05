#!/bin/bash -x

# Dirty ugly hack for inserting data into values.yaml
sed -i '' "s|#GITLAB_ROOT_PASSWORD#|$GITLAB_ROOT_PASSWORD|g" values.yaml
	
	#sso_url=$(cat okta/ssoUrl)
#sed -i '' "s|#SAML_TARGET_URL#|$sso_url|g" values.yaml

#fingerprint=$(openssl x509 -in okta/okta.pem -inform pem -noout -fingerprint | cut -d'=' -f2)
#sed -i '' "s|#SAML_CERT_FINGERPRINT#|$fingerprint|g" values.yaml


