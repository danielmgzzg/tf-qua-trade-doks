
SHELL := /bin/bash
.ONESHELL:

ENV_FILE ?= .env

include $(ENV_FILE)
export

TF_DIR := .
VAR_FILE ?= environments/prd.tfvars
ARGS := $(if $(VAR_FILE),-var-file=$(VAR_FILE),)

init:
	terraform -chdir=$(TF_DIR) init

plan: init
	terraform -chdir=$(TF_DIR) plan $(ARGS) \
		-var doppler_token=$$DOPPLER_TOKEN \
		-var doppler_project=$$DOPPLER_PROJECT \
		-var doppler_config=$$DOPPLER_CONFIG

apply:
	terraform -chdir=$(TF_DIR) apply $(ARGS) -auto-approve \
		-var doppler_token=$$DOPPLER_TOKEN \
		-var doppler_project=$$DOPPLER_PROJECT \
		-var doppler_config=$$DOPPLER_CONFIG

destroy:
	terraform -chdir=$(TF_DIR) destroy $(ARGS)  -auto-approve \
		-var doppler_token=$$DOPPLER_TOKEN \
		-var doppler_project=$$DOPPLER_PROJECT \
		-var doppler_config=$$DOPPLER_CONFIG

kubeconfig:
	terraform -chdir=. apply -auto-approve -target=local_file.kubeconfig_prd

k9s: kubeconfig
	KUBECONFIG=./kubeconfig k9s

kubectl: kubeconfig
	KUBECONFIG=./kubeconfig kubectl get ns
