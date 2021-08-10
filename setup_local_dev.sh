export CLUSTER=$1

secrethub inject -i environments/$CLUSTER.auto.tfvars.json.tpl -o $CLUSTER.auto.tfvars.json
secrethub inject -i environments/$CLUSTER.json.tpl -o $CLUSTER.json
