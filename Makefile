
SHELL := /bin/bash
.ONESHELL:

ENV_FILE ?= .env

include $(ENV_FILE)
export

TF_DIR := .
VAR_FILE ?= environments/prd.tfvars
ARGS := $(if $(VAR_FILE),-var-file=$(VAR_FILE),)
# Local backtest config (adjust path to whatever you use)
CONFIG    ?= ../config.backtest.json
# Strategy name as used by freqtrade (module.Class)
STRATEGY  := SmaRsiATRStrategy
UV ?= uv
PAIRS     := BTC/USDT ETH/USDT
TIMEFRAME := 1h
DAYS      := 7
TIMERANGE := 20240101-20241101

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


install:
	cd strategies && uv sync

create-user-data:
	cd strategies && uv run freqtrade create-userdir \
	--userdir ./user_data

download-data:
	cd strategies && uv run freqtrade download-data \
		--config $(CONFIG) \
		--dl-trades \
		--trading-mode spot \
		--timeframe $(TIMEFRAME) \
		--pairs $(PAIRS) \
		--timerange $(TIMERANGE) \
		--erase

backtest:
	cd strategies && $(UV) run freqtrade backtesting \
		--config $(CONFIG) \
		--strategy $(STRATEGY) \
		--strategy-path src \
		--timeframe 1h \
		--timerange $(TIMERANGE) \
		--export trades