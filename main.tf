terraform {
  required_version = ">= 1.6"
  required_providers {
    digitalocean = { source = "digitalocean/digitalocean", version = "~> 2.40" }
    helm         = { source = "hashicorp/helm", version = "~> 2.13" }
    kubernetes   = { source = "hashicorp/kubernetes", version = "~> 2.29" }
    doppler      = { source = "DopplerHQ/doppler", version = "~> 1.13" }
  }
}

# Doppler provider (use alias name consistently)
provider "doppler" {
  doppler_token = var.doppler_token
  alias         = "default"
}

# Pull once from Doppler (shared for DO + Cloudflare)
data "doppler_secrets" "all" {
  count    = (var.use_doppler_for_cloudflared || var.use_doppler_for_do) ? 1 : 0
  project  = var.doppler_project
  config   = var.doppler_config
  provider = doppler.default
}

locals {
  do_token_value = (
    var.use_doppler_for_do
    ? try(data.doppler_secrets.all[0].map[var.doppler_do_token_key], "")
    : coalesce(var.do_token, "")
  )

  cloudflare_token_value = (
    var.enable_cloudflared ? (
      var.use_doppler_for_cloudflared
      ? try(data.doppler_secrets.all[0].map[var.doppler_cloudflare_token_key], "")
      : var.cloudflare_tunnel_token
    ) : ""
  )
}

module "cluster" {
  source      = "./modules/cluster/do_doks"
  do_token    = local.do_token_value
  name        = var.cluster_name
  region      = var.region
  node_size   = var.node_size
  min_nodes   = var.min_nodes
  max_nodes   = var.max_nodes
  k8s_version = var.k8s_version
}


# K8s Secret for cloudflared token (created whether token comes from Doppler or var)
resource "kubernetes_namespace" "ingress" {
  count = var.enable_cloudflared ? 1 : 0
  metadata {
    name = var.ingress_namespace
  }
}

resource "kubernetes_secret" "cloudflared_token" {
  count = var.enable_cloudflared ? 1 : 0
  metadata {
    name      = "cloudflared-token"
    namespace = var.ingress_namespace
  }
  data = {
    token = base64encode(local.cloudflare_token_value)
  }
  depends_on = [kubernetes_namespace.ingress]
}

module "cloudflared" {
  count                = var.enable_cloudflared ? 1 : 0
  source               = "./modules/addons/cloudflared_tunnel"
  namespace            = var.ingress_namespace
  existing_secret_name = "cloudflared-token"
  mappings             = var.cloudflare_mappings
}

module "freqtrade_bot" {
  count       = var.enable_bot ? 1 : 0
  source      = "./modules/apps/freqtrade_bot"
  namespace   = var.bot_namespace
  name        = var.bot_name
  mode        = "dry"
  strategy    = var.bot_strategy
  secret_ref  = ""
  persistence = var.bot_persistence
  resources   = var.bot_resources
}
