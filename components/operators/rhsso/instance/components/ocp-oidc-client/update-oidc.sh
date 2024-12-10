RETRIES=0

echo "Attempting to get cluster base domain URL"
DOMAIN_URL=$(oc get dns/$DNS_NAME -o jsonpath={.spec.baseDomain})
API_URL="https://api."$DOMAIN_URL":6443"

echo "Using OpenShift API at "$API_URL

echo "Attempting to get cluster app URL from ingress"
APP_URL=$(oc get ingresses.config/$INGRESS_NAME -o jsonpath={.spec.domain})
KEYCLOAK_URL="https://keycloak-"$NAMESPACE"."$APP_URL


echo "Connecting to Keycloak at "$KEYCLOAK_URL
echo "Verifying Keycloak is available"

until [ \
  "$(curl -k -s -w '%{http_code}' -o /dev/null "$KEYCLOAK_URL")" \
  -eq 200 ]
do
  if [[ "$RETRIES" -eq 10 ]]; then
    echo "Keycloak unavailable after 10 retries"
    exit 1
  fi
  (( RETRIES++ ))
  echo "Keycloak did not respond.  Retrying after 60 seconds. Attempt "$RETRIES
  sleep 60


done

echo "Getting the oidc secret"

oc extract secret/openshift-oidc-secret --keys=token --to=/tmp $1>/dev/null

oc extract secret/credential-composer-ai-rhsso --to=/tmp $1>/dev/null

CLIENT_SECRET=$(cat /tmp/token)
KEYCLOAK_USER=$(cat /tmp/ADMIN_USERNAME)
KEYCLOAK_PASS=$(cat /tmp/ADMIN_PASSWORD)

echo "Retrieving access token from Keycloak"

access_token=$(curl -k -s -X POST "$KEYCLOAK_URL/auth/realms/master/protocol/openid-connect/token" \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'username='$KEYCLOAK_USER \
--data-urlencode 'password='$KEYCLOAK_PASS \
--data-urlencode 'grant_type=password' \
--data-urlencode 'client_id=admin-cli' | jq --raw-output '.access_token')

if [ -z "${access_token}" ]; then
  echo "Access token was not retrieved from keycloak."
  exit 1
fi

echo "Retrieving openshift-v4 idp manifest"
curl -k -s "$KEYCLOAK_URL/auth/admin/realms/openshift-ai/identity-provider/instances/openshift-v4" \
--header 'Authorization: Bearer '$access_token -o /tmp/idp.json

echo "Updating openshift-v4 idp manifest"

jq --arg CLIENT_SECRET $CLIENT_SECRET --arg API_URL $API_URL \
  '(.config.clientSecret) |= $CLIENT_SECRET | (.config.baseUrl) |= $API_URL' \
  /tmp/idp.json > /tmp/idp-updated.json

echo "Reapplying openshift-v4 idp manifest"

curl -k -s -X PUT "$KEYCLOAK_URL/auth/admin/realms/openshift-ai/identity-provider/instances/openshift-v4" \
--header 'Authorization: Bearer '$access_token \
--header 'Content-Type: application/json' \
--data @/tmp/idp-updated.json

echo "The IDP has been updated with the openshift-oidc token."

echo "Retrieving backend-service client"
curl -k -s "$KEYCLOAK_URL/auth/admin/realms/openshift-ai/clients" \
--header 'Authorization: Bearer '$access_token -o /tmp/clients.json

echo "Updating backend-service idp manifest"
jq '.[] | select(.clientId == "backend-service")' /tmp/clients.json > /tmp/backend-service.json
CLIENT_ID=$(jq '.id' /tmp/backend-service.json | tr -d '"')
cat /tmp/backend-service.json

REDIRECT_URIS=("https://quarkus-router-llm-"$COMPOSER_NAMESPACE"."$APP_URL"/*")

jq --arg redirect $REDIRECT_URIS \
  '.redirectUris = [$redirect] ' /tmp/backend-service.json > /tmp/backend-updated.json 
curl -k -X PUT "$KEYCLOAK_URL/auth/admin/realms/openshift-ai/clients/"$CLIENT_ID \
--header 'Authorization: Bearer '$access_token \
--header 'Content-Type: application/json' \
--data @/tmp/backend-updated.json

cat /tmp/backend-updated.json
# echo "Update Client with a random secret"
# curl -X POST '$KEYCLOAK_URL/auth/admin/realms/openshift-ai/clients/'$CLIENT_ID'/client-secret' \
# --header 'Authorization: Bearer' $access_token \
# --header 'Content-Type: application/json' -o /tmp/secret.json

echo "Updating service account with redirect URIs"
oc patch serviceaccount openshift-oidc -p '{"metadata":{"annotations": {"serviceaccounts.openshift.io/oauth-redirecturi.first": "https://keycloak-'$NAMESPACE'.'$APP_URL'/auth/realms/openshift-ai/broker/openshift-v4/endpoint"}}}'
 
rm -rf /tmp/*.json /tmp/token /tmp/ADMIN_USERNAME /tmp/ADMIN_PASSWORD

# curl -X POST '$KEYCLOAK_URL/auth/admin/realms/openshift-ai/clients/325c88ef-88a2-4a84-9843-5acf4104d7f1/client-secret' \
# --header 'Authorization: Bearer' $access_token \
# --header 'Content-Type: application/json' -o /tmp/secret.json