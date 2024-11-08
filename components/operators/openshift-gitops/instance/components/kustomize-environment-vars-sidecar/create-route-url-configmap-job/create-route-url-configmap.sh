#!/bin/sh

set -e

echo "Attempting to get cluster app URL"
APP_URL=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})

echo
echo "App URL: ${APP_URL}"
echo "Creating plugin-substitution-env-vars configmap"
oc create configmap plugin-substitution-env-vars --from-literal=SUB_DOMAIN=${APP_URL}
