# keycloak

Installs the Red Hat Build of Keycloak operator and/or instance.

## Usage

NOTE: Currently hard coded to install in namespace `composer-ai-rhbk`

### Install the operator only

The current *overlays* available are for the following channels:

* [stable](operator/overlays/stable)

```
oc apply -k rhbk/operator/overlays/stable
```


### Install an instance of Keycloak

```
oc apply -k rhbk/instance/overlays/<overlay-name>
```
The current overlays are available for the following cases:

* [keycloak-standalone](instance/overlays/keycloak-standalone) - A Keycloak instance with a Postgres database and a default realm imported for composer-ai

### Install all components

```
oc apply -k rhsso/aggregate/overlays/<overlay-name>
```

#### Oidc Client Component

This component uses a `Job` in create components for Keycloak to integrate with OpenShift OIDC endpoints.  

The following items are created:
* `ServiceAccount` `openshift-oidc` - A service account used as an oidc provider.  This allows Keycloak to use OpenShift as an IDP.  One or more annotations for redirect uris must correctly point back to Keycloak. See patch-sa.yaml for example substitutions. See [Service accounts as OAuth clients](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/authentication_and_authorization/using-service-accounts-as-oauth-client#service-accounts-as-oauth-clients_using-service-accounts-as-oauth-client) for more details.  
* `Secret` `openshift-oidc-secret` - A secret providing a long lasting token for the `openshift-oidc` service account.  This is required as Keycloak requires a token in the OpenShift IDP configuration.  See [Service Accounts Admin](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#create-token) for more details.
* `Role` and `RoleBinding` giving permissions to the Job to read secrets required to use the Keycloak API to update secrets and config.
* `Job` `update-idp-credentials` - A Job that runs as a PostSync hook in Argo in order to apply the default composer-ai Keycloak realm and related service account annotations. NOTE: This will run after every Argo sync, values will be reset after any manifest changes. 
* `ConfigMap` `oidc-job-cm` - This imports the files `realm.json`, the realm configuration for composer-ai, and `update-oidc.sh`, the shell script for the update Job.  These are mounted as files when the Job runs.

NOTE: The job sets the `backend-service` client redirectUris to '*'.  This should be changed for any non-demo workload to allow minimal registered application permissions. 

#### Postgres Component

The Red Hat Build of Keycloak requires providing a Postgresql instance if persistence is required.  This component creates secrets for the database credentials, creates a Postgres StatefulSet and Service, and patches the Keycloak CR to connect. 

NOTE: Do not store important credentials for databases in Secrets in a non-proof of concept environment.