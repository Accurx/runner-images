#!/bin/bash

sudo mkdir -p /agent
cd /agent

## INSTALL PRE-REQUISITES
sudo apt update; sudo apt install -y git wget
sudo wget https://vstsagentpackage.azureedge.net/agent/4.248.1/vsts-agent-linux-x64-4.248.1.tar.gz ## agent binary
sudo tar -xf vsts-agent-linux-x64-4.248.1.tar.gz
sudo curl -sL https://vstsagenttools.blob.core.windows.net/tools/ElasticPools/Linux/16/enableagent.sh -o enableagent.sh ## user setup script

export MANAGED_IDENTITY_ID=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r '.compute.tagsList.[] | select(.name == "ManagedIdentityId") | .value')
export AZDO_POOL=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r '.compute.tagsList.[] | select(.name == "AgentPool") | .value')
export KEYVAULT_NAME=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r '.compute.tagsList.[] | select(.name == "KeyVaultName") | .value')

az login --identity --allow-no-subscriptions --username ${MANAGED_IDENTITY_ID}
export DEVOPS_PAT=$(az keyvault secret show  --id "https://${KEYVAULT_NAME}.vault.azure.net/secrets/devops-bot-pat" | jq -r '.value')

## Create log file that enableagent.sh for some reason requires to exist
sudo mkdir -p /var/log/azure/Microsoft.VisualStudio.Services.TeamServicesAgentLinux
sudo touch /var/log/azure/Microsoft.VisualStudio.Services.TeamServicesAgentLinux/enableagent.log

## ENABLE SCRIPTS
sudo chmod +x /agent/*.sh

## INSTALL AND REGISTER AGENT
sudo ./enableagent.sh https://dev.azure.com/accurx ${AZDO_POOL} ${DEVOPS_PAT}
