# BWIA Smart Code Builder - Makefile
# Estandar AXMOS Cloud Run (Podman + Artifact Registry)

PROJECT_ID := $(GCP_PROJECT_ID)
SERVICE_NAME := bwia-smart-code-builder
REGION := us-east5
REGISTRY := $(REGION)-docker.pkg.dev
IMAGE_NAME := $(REGISTRY)/$(PROJECT_ID)/$(SERVICE_NAME)/$(SERVICE_NAME)
TAG ?= latest
PORT := 8000

.PHONY: setup auth-podman build push deploy local web logs all

setup:
	gcloud services enable \
		artifactregistry.googleapis.com \
		run.googleapis.com \
		aiplatform.googleapis.com
	gcloud artifacts repositories create $(SERVICE_NAME) \
		--repository-format=docker \
		--location=$(REGION) \
		--description="BWIA Smart Code Builder images" \
		|| true

auth-podman:
	gcloud auth print-access-token | podman login -u oauth2accesstoken \
		--password-stdin $(REGISTRY)

build:
	podman build --platform linux/amd64 -t $(IMAGE_NAME):$(TAG) .

push: build auth-podman
	podman push $(IMAGE_NAME):$(TAG)

deploy: push
	gcloud run deploy $(SERVICE_NAME) \
		--image $(IMAGE_NAME):$(TAG) \
		--platform managed \
		--region $(REGION) \
		--allow-unauthenticated \
		--timeout 300 \
		--memory 1Gi \
		--cpu 1 \
		--max-instances 5 \
		--min-instances 0 \
		--port $(PORT) \
		--set-env-vars "GCP_PROJECT_ID=$(PROJECT_ID),GCP_LOCATION=global"

local:
	adk run smart_code_builder

web:
	adk web smart_code_builder

logs:
	gcloud run services logs read $(SERVICE_NAME) \
		--region $(REGION) --limit 50

all: setup build push deploy
