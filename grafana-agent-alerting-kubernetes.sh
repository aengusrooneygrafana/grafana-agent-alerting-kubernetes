#!/bin/bash 

#### Create k8s cluster  (shift option r to run)

export THEDATE=`date +%y%m%d%H`
gcloud container clusters create se-rooney-$THEDATE --num-nodes 3 
kubectl config current-context

#### Create new Grafana.com org or stack on 

open -g -a "Google Chrome" https://grafana.com/orgs/aengusrooneytest 

#### SOURCE THE ENVIRONMENT VARIABLES 

cat << EOF > set_env.sh
#### ENVIRONMENT - METRICS
export YOUR_CLUSTER_NAME=cloud
export YOUR_REMOTE_WRITE_URL=https://prometheus-us-central1.grafana.net/api/prom/push
export YOUR_REMOTE_WRITE_USERNAME=
export YOUR_REMOTE_WRITE_PASSWORD=
export NAMESPACE=default
export MANIFEST_URL=https://raw.githubusercontent.com/grafana/agent/main/production/kubernetes/agent-bare.yaml
#### ENVIRONMENT - LOGS
export YOUR_LOKI_ENDPOINT=https://logs-prod-us-central1.grafana.net/loki/api/v1/push
export YOUR_LOKI_USERNAME=
export YOUR_LOKI_PASSWORD=
export YOUR_NAMESPACE=default
export NAMESPACE=default
#### ENVIRONMENT - TRACES
export YOUR_TEMPO_ENDPOINT=tempo-us-central1.grafana.net:443
export YOUR_TEMPO_USER=
export YOUR_TEMPO_PASSWORD=
export YOUR_NAMESPACE=default
#### ENVIRONMENT - ALERTMANAGER 
export AM_ADDRESS=https://prometheus-prod-10-prod-us-central-0.grafana.net
export AM_ID=
export AM_PASSWORD=
EOF

chmod a+x set_env.sh 
source ../set_env.sh

env | grep -e YOUR_REMOTE_WRITE_USERNAME 

#### APPLY THE METRICS AGENT AND CONFIG 

envsubst < agent-metrics.yaml | kubectl apply -n default -f - 
envsubst < agent-metrics-configmap.yaml | kubectl apply -n default -f -
kubectl rollout restart deployment/grafana-agent

#### APPLY THE LOGS AGENT AND CONFIG 

envsubst < agent-logs.yaml | kubectl apply -n default -f -
envsubst < agent-logs-configmap.yaml | kubectl apply -n default -f -
kubectl rollout restart ds/grafana-agent-logs

#### APPLY THE TRACES AGENT AND CONFIG 

envsubst < agent-traces.yaml | kubectl apply -n default -f -
envsubst < agent-traces-configmap.yaml | kubectl apply -n default -f -
kubectl rollout restart deployment/grafana-agent-traces

#### CHECK PODS RUNNING OK 

kc get po -n default 

#### BROWSE METRIECS AND LOGS 

open -g -a "Google Chrome"  https://aengusrooney0301.grafana.net/explore

#### Alerting  

# k8s integration installs a new set of alerts  

open -g -a "Google Chrome" https://aengusrooney0301.grafana.net/a/grafana-easystart-app/integrations-management/integrations 

# CORTEXTOOL 

cortextool rules load k8s_rules.yml --address=$AM_ADDRESS --id=$AM_ID --key=$AM_PASSWORD 
cortextool rules list --address=$AM_ADDRESS --id=$AM_ID --key=$AM_PASSWORD 

#### Tracing app 

open -g -a "Google Chrome" https://grafana.com/blog/2021/08/31/how-istio-tempo-and-loki-speed-up-debugging-for-microservices/

####

