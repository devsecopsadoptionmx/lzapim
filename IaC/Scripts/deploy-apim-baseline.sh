#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ -f "$script_dir/../../.env" ]]; then
	echo "Loading .env"
	source "$script_dir/../../.env"
  echo "$script_dir/../../.env"
fi

if [[ ${#AZURE_LOCATION} -eq 0 ]]; then
  echo 'ERROR: Missing environment variable AZURE_LOCATION' 1>&2
  exit 6
else
  AZURE_LOCATION="${AZURE_LOCATION%$'\r'}"
  echo "AZURE_LOCATION='$AZURE_LOCATION'" 
fi

if [[ ${#RESOURCE_NAME_PREFIX} -eq 0 ]]; then
  echo 'ERROR: Missing environment variable RESOURCE_NAME_PREFIX' 1>&2
  exit 6
else
  RESOURCE_NAME_PREFIX="${RESOURCE_NAME_PREFIX%$'\r'}"
fi

if [[ ${#ENVIRONMENT_TAG} -eq 0 ]]; then
  echo 'ERROR: Missing environment variable ENVIRONMENT_TAG' 1>&2
  exit 6
else
  ENVIRONMENT_TAG="${ENVIRONMENT_TAG%$'\r'}"
fi

if [[ ${#RANDOM_IDENTIFIER} -eq 0 ]]; then
  chars="abcdefghijklmnopqrstuvwxyz"
  random_string=""
  for i in {1..3}; do
      random_char="${chars:RANDOM%${#chars}:1}"
      random_string+="$random_char"
  done
  echo "RANDOM_IDENTIFIER='$random_string'" >> "$script_dir/../../.env"
else
  random_string="${RANDOM_IDENTIFIER}"
fi

cat << EOF > "$script_dir/../../IaC/parameters.json"
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workloadName" :{
        "value": "${RESOURCE_NAME_PREFIX}"
    },
    "environment" :{
        "value": "${ENVIRONMENT_TAG}"
    },
    "identifier" :{
        "value": "${random_string}"
    }
  }
}
EOF

deployment_name="apim-baseline-${RESOURCE_NAME_PREFIX}"

cd "$script_dir/../../IaC/"
echo "=="
echo "== Starting bicep deployment ${deployment_name}"
echo "=="
output=$(az deployment sub create \
  --template-file main.bicep \
  --name "$deployment_name" \
  --parameters parameters.json \
  --location "$AZURE_LOCATION" \
  --output json)

echo "== Completed bicep deployment ${deployment_name}"

echo "$output" | jq "[.properties.outputs | to_entries | .[] | {key:.key, value: .value.value}] | from_entries" > "$script_dir/../../IaC/output.json"

apimStarterSubscriptionKey=$(cat "$script_dir/../../IaC/output.json" | jq -r '.apimStarterSubscriptionKey')

# testUri="curl -k -v -H 'Host: ${APPGATEWAY_FQDN}' -H 'Ocp-Apim-Subscription-Key: ${apimStarterSubscriptionKey}' https://${appGatewayPublicIpAddress}/echo/resource?param1=sample"
# echo "Test the deployment by running the following command: ${testUri}"
# echo -e "\n"