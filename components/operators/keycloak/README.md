# keycloak

Installs the Red Hat SSO (keycloak) operator

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [stable](operator/overlays/stable)

## Usage

### Install the operator

```
oc apply -k keycloak/operator/overlays/stable
```

### Install an instance of Keycloak

```
oc apply -k keycloak/instance/overlays/<overlay-name>
```

Next, use the `openshift-oidc` service account to get a token and update the idp password in keycloak.

```
oc create token openshift-oidc -n composer-ai-keycloak
```

In Keycloak, change realms to `openshift-ai`, click `Identity Providers`, `openshift-v4`, then update the `Client Secret` with the value returned above.