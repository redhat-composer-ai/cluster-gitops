RETRIES=0

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

jq --arg CLIENT_SECRET $CLIENT_SECRET '(.config.clientSecret) |= $CLIENT_SECRET' /tmp/idp.json > /tmp/updated.json

echo "Reapplying openshift-v4 idp manifest"

curl -k -s -X PUT "$KEYCLOAK_URL/auth/admin/realms/openshift-ai/identity-provider/instances/openshift-v4" \
--header 'Authorization: Bearer '$access_token \
--header 'Content-Type: application/json' \
--data @/tmp/updated.json

rm -rf /tmp/*.json /tmp/token /tmp/ADMIN_USERNAME /tmp/ADMIN_PASSWORD

echo "The IDP has been updated with the openshift-oidc token."

# curl -X POST '$KEYCLOAK_URL/auth/admin/realms/openshift-ai/clients/325c88ef-88a2-4a84-9843-5acf4104d7f1/client-secret' \
# --header 'Authorization: Bearer' $access_token \
# --header 'Content-Type: application/json' -o /tmp/secret.json