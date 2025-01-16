RETRIES=0

echo "Attempting to get cluster app URL from ingress"
APP_URL=$(oc get ingresses.config/$INGRESS_NAME -o jsonpath={.spec.domain})

openssl req -subj '/CN=keyloak-'$NAMESPACE'.'$APP_URL'/O=Test Keycloak./C=US' -newkey rsa:2048 -nodes -keyout /tmp/key.pem -x509 -days 365 -out /tmp/certificate.pem

oc get secret rhbk-tls-secret -n $NAMESPACE

if [ $? -ne 0 ]; then
  oc create secret tls rhbk-tls-secret --cert /tmp/certificate.pem --key /tmp/key.pem -n $NAMESPACE
else
  echo "Secret rhbk-tls-secret already exists"
fi

