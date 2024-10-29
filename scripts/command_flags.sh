# Help function
function show_help {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --ocp_version=4.11    Target Openshift Version"
  echo "  --base_domain=<domain> Base domain for the cluster (i.e. apps.cluster-GUID.GUID.sandbox.openshift.com)"
  echo "                         Default: Will be set to the cluster domain of currently connected cluster if not set"                          
  echo "                         Note: \`--update-base-domain\` must be set or this will be ignored"
  echo " --update_base_domain    If set, will update the base domain in the git repo"
  echo "  --BOOTSTRAP_DIR=<bootstrap_directory>    Base folder inside of bootstrap/overlays (Optional, pick during script execution if not set)"
  echo "  --timeout=45          Timeout in seconds for waiting for each resource to be ready"
  echo "  -f                    If set, will update the `patch-application-repo-revision` folder inside of your overlay with the current git information and push a checkin"
  echo "  --help                Show this help message"
}

for arg in "$@"
do
  case $arg in
    --base_domain=*)
    export BASE_DOMAIN="${arg#*=}"
    shift
    ;;
    --ocp_version=*)
    export OCP_VERSION="${arg#*=}"
    echo "Using OCP Bianaires Version: ${OCP_VERSION}"
    shift
    ;;
    --bootstrap_dir=*)
    export BOOTSTRAP_DIR="${arg#*=}"
    echo "Using Bootstrap Directory: ${BOOTSTRAP_DIR}"
    shift
    ;;
    -f)
    export FORCE=true
    echo "Force set, using current git branch"
    shift
    ;;
    -update_base_domain)
    export UPDATE_BASEDOMAIN=true
    echo "Update Base Domain set, will update the base domain on the git repo"
    shift
    ;;
    --help)
    show_help
    exit 0
    ;;
  esac
done


if [ -z "$BASE_DOMAIN" ] && [ UPDATE_BASEDOMAIN ]; then
  BASE_DOMAIN=$(get_cluster_domain)
  echo Setting Base Domain $BASE_DOMAIN
fi