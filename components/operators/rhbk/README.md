# keycloak

Installs the Red Hat Build of Keycloak operator.

## Usage

NOTE: Currently hard coded to install in namespace `composer-ai-app`

### Install the operator only

The current *overlays* available are for the following channels:

* [stable](operator/overlays/stable)

```
oc apply -k rhbk/operator/overlays/stable-v26
```
