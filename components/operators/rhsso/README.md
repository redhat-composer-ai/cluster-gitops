# keycloak

Installs the Red Hat SSO (keycloak) operator and/or instance.

## Usage

### Install the operator

The current *overlays* available are for the following channels:

* [stable](operator/overlays/stable)

```
oc apply -k rhsso/operator/overlays/stable
```


### Install an instance of Keycloak

```
oc apply -k rhsso/instance/overlays/<overlay-name>
```
The current overlays are available for the following cases:

* [keycloak-standalone](instance/overlays/keycloak-standalone) - A base Keycloak instance with no realm configuration
* [aws-ocp-oidc](instance/overlays/aws-ocp-oidc) - A Keycloak instance base with a component configuring a realm containing a backend client and configuration for an OpenShift IDP

### Install all components

```
oc apply -k rhsso/aggregate/overlays/<overlay-name>
```

#### Oidc Client Component

This component installs the instance of Keycloak and the sets up the following items to use OpenShift as and IDP as well as setting up a client for the backend service to use.

The following items are created:
* `KeycloakRealm` `openshift-realm` - Defines the `openshift-ai` realm as well as the `backend-service` client and `openshift-v4` idp.  Contains baseUrls and secrets that must be changed for the application to authenticate correctly. See patch-realm.yaml for example substitutions. NOTE: The KeycloakRealm will only create the initial realm.  If the realm already exists, changes to the CR [will not update the realm in Keycloak](https://docs.redhat.com/en/documentation/red_hat_single_sign-on/7.6/html/server_installation_and_configuration_guide/operator#realm-cr).  
* `ServiceAccount` `openshift-oidc` - A service account used as an oidc provider.  This allows Keycloak to use OpenShift as an IDP.  One or more annotations for redirect uris must correctly point back to Keycloak. See patch-sa.yaml for example substitutions. See [Service accounts as OAuth clients](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/authentication_and_authorization/using-service-accounts-as-oauth-client#service-accounts-as-oauth-clients_using-service-accounts-as-oauth-client) for more details.  
* `Secret` `openshift-oidc-secret` - A secret providing a long lasting token for the `openshift-oidc` service account.  This is required as Keycloak requires a token in the OpenShift IDP configuration.  See [Service Accounts Admin](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#create-token) for more details.
* `Role` and `RoleBinding` giving permissions to the Job to read secrets required to use the Keycloak API to update secrets and config.
* `Job` `update-idp-credentials` - A Job that runs as a PostSync hook in Argo in order to update required secrets and redirect/baseUrls within the Keycloak realm. 