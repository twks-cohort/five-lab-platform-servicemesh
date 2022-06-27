#!/usr/bin/env bash
set -e

function version_alert() {
  export TABLE_COLOR=$ALERT_TABLE_COLOR
  echo "version alert"
  # every 7 days, also send a slack message
  if (( "$(date +%d)" % 7 )); then
    export payload="{'text': '$1' }"
    curl -X POST -H 'Content-type: application/json' --data "$payload" $LAB_EVENTS_CHANNEL_WEBHOOK
  fi
}

# current versions table
export TABLE="| dependency | sandbox-us-east-2 | prod-us-east-1 |\\\\n|----|----|----|\\\\n"
export ISTIO_VERSIONS="| istio revision |"
export EXTERNAL_DNS_VERSIONS="| external-dns |"
export CERT_MANAGER_VERSIONS="| cert-manager* |"
export KIALI_VERSIONS="| kiali* |"

echo "generate markdown table with the desired versions of the services managed by the lab-platform-servicemesh pipeline for all clusters"
declare -a clusters=(sandbox-us-east-2 prod-us-east-1)

for cluster in "${clusters[@]}";
do
  echo "cluster: $cluster"

  # append environment ISTIO version
  export ISTIO_VERSION=$(cat environments/$cluster.install.json | jq -r .istio_version)
  export DESIRED_ISTIO_VERSION=$ISTIO_VERSION
  export ISTIO_VERSIONS="$ISTIO_VERSIONS $ISTIO_VERSION |"
  echo "DESIRED_ISTIO_VERSION: $DESIRED_ISTIO_VERSION"

  # append environment EXTERNAL_DNS version
  export DESIRED_EXTERNAL_DNS_VERSION=$(cat environments/$cluster.install.json | jq -r .external_dns_version)
  export EXTERNAL_DNS_VERSIONS="$EXTERNAL_DNS_VERSIONS $DESIRED_EXTERNAL_DNS_VERSION |"
  echo "DESIRED_EXTERNAL_DNS_VERSION: $DESIRED_EXTERNAL_DNS_VERSION"

  # append environment CERT_MANAGER version
  export DESIRED_CERT_MANAGER_VERSION=$(cat environments/$cluster.install.json | jq -r .cert_manager_chart_version)
  export CERT_MANAGER_VERSIONS="$CERT_MANAGER_VERSIONS $DESIRED_CERT_MANAGER_VERSION |"
  echo "DESIRED_CERT_MANAGER_VERSION: $DESIRED_CERT_MANAGER_VERSION"

  # append environment KIALI version
  export DESIRED_KIALI_VERSION=$(cat environments/$cluster.install.json | jq -r .kiali_version)
  export KIALI_VERSIONS="$KIALI_VERSIONS $DESIRED_KIALI_VERSION |"
  echo "DESIRED_KIALI_VERSION: $DESIRED_KIALI_VERSION"

done

# assumeble markdown table
export CURRENT_TABLE="$TABLE$ISTIO_VERSIONS\\\\n$EXTERNAL_DNS_VERSIONS\\\\n$CERT_MANAGER_VERSIONS\\\\n$KIALI_VERSIONS\\\\n\\\\n*Helm chart versions\\\\n"

# current versions table
declare TABLE="| available |\\\\n|----|\\\\n"
declare ISTIO_VERSIONS="|"
declare EXTERNAL_DNS_VERSIONS="|"
declare CERT_MANAGER_VERSIONS="|"
declare KIALI_VERSIONS="|"

echo "generate markdown table with the available versions of the services managed by the lab-platform-servicemesh pipeline for all clusters"

# fetch the latest release versions
python scripts/latest_versions.py

export LATEST_ISTIO_VERSION=$(cat latest_versions.json | jq -r .istio_version)
export ISTIO_VERSIONS="$ISTIO_VERSIONS $LATEST_ISTIO_VERSION |"
echo "LATEST_ISTIO_VERSION: $LATEST_ISTIO_VERSION"

export LATEST_EXTERNAL_DNS_VERSION=$(cat latest_versions.json | jq -r .external_dns_version)
export EXTERNAL_DNS_VERSIONS="$EXTERNAL_DNS_VERSIONS $LATEST_EXTERNAL_DNS_VERSION |"
echo "LATEST_EXTERNAL_DNS_VERSION: $LATEST_EXTERNAL_DNS_VERSION"

export LATEST_CERT_MANAGER_VERSION=$(cat latest_versions.json | jq -r .cert_manager_version)
export CERT_MANAGER_VERSIONS="$CERT_MANAGER_VERSIONS $LATEST_CERT_MANAGER_VERSION |"
echo "LATEST_CERT_MANAGER_VERSION: $LATEST_CERT_MANAGER_VERSION"

export LATEST_KIALI_VERSION=$(cat latest_versions.json | jq -r .kiali_version)
export KIALI_VERSIONS="$KIALI_VERSIONS $LATEST_KIALI_VERSION |"
echo "LATEST_KIALI_VERSION: $LATEST_KIALI_VERSION"

# assumeble markdown table
export LATEST_TABLE="$TABLE$ISTIO_VERSIONS\\\\n$EXTERNAL_DNS_VERSIONS\\\\n$CERT_MANAGER_VERSIONS\\\\n$KIALI_VERSIONS\\\\n"

echo "check production current versions against latest"
export TABLE_COLOR="green"
export ALERT_TABLE_COLOR="pink"

if [[ $DESIRED_ISTIO_VERSION != $LATEST_ISTIO_VERSION ]]; then
  version_alert "New Istio version available: $LATEST_ISTIO_VERSION"
fi
if [[ $DESIRED_EXTERNAL_DNS_VERSION != $LATEST_EXTERNAL_DNS_VERSION ]]; then
  version_alert "New external-dns version available: $LATEST_EXTERNAL_DNS_VERSION"
fi
if [[ $DESIRED_CERT_MANAGER_VERSION != $LATEST_CERT_MANAGER_VERSION ]]; then
  version_alert "New cert-manager version available: $LATEST_CERT_MANAGER_VERSION"
fi
if [[ $DESIRED_KIALI_VERSION != $LATEST_KIALI_VERSION ]]; then
  version_alert "New kiali version available: $LATEST_KIALI_VERSION"
fi

echo "insert markdown into dashboard.json"
cp tpl/dashboard.json.tpl observe/dashboard.json

if [[ $(uname) == "Darwin" ]]; then
  gsed -i "s/CURRENT_TABLE/$CURRENT_TABLE/g" observe/dashboard.json
  gsed -i "s/LATEST_TABLE/$LATEST_TABLE/g" observe/dashboard.json
  gsed -i "s/TABLE_COLOR/$TABLE_COLOR/g" observe/dashboard.json
else
  sed -i "s/CURRENT_TABLE/$CURRENT_TABLE/g" observe/dashboard.json
  sed -i "s/LATEST_TABLE/$LATEST_TABLE/g" observe/dashboard.json
  sed -i "s/TABLE_COLOR/$TABLE_COLOR/g" observe/dashboard.json
fi

python scripts/dashboard.py
