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
  count    = (var.use_doppler_for_cloudflared || var.use_doppler_for_do || var.use_doppler_for_freqtrade) ? 1 : 0
  project  = var.doppler_project
  config   = var.doppler_config
  provider = doppler.default
}

locals {
  bots = var.freqtrade_bots

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
  # Helpers to pull from doppler_secrets map if enabled, otherwise empty string
  freqtrade_api_username_value = (
    var.use_doppler_for_freqtrade
    ? try(data.doppler_secrets.all[0].map[var.doppler_freqtrade_api_username_key], "")
    : ""
  )

  freqtrade_api_password_value = (
    var.use_doppler_for_freqtrade
    ? try(data.doppler_secrets.all[0].map[var.doppler_freqtrade_api_password_key], "")
    : ""
  )

  freqtrade_jwt_secret_key_value = (
    var.use_doppler_for_freqtrade
    ? try(data.doppler_secrets.all[0].map[var.doppler_freqtrade_jwt_secret_key_key], "")
    : ""
  )

  kraken_api_key_value = (
    var.use_doppler_for_freqtrade
    ? try(data.doppler_secrets.all[0].map[var.doppler_kraken_api_key_key], "")
    : ""
  )

  kraken_api_secret_value = (
    var.use_doppler_for_freqtrade
    ? try(data.doppler_secrets.all[0].map[var.doppler_kraken_api_secret_key], "")
    : ""
  )

  freqtrade_config_live = jsonencode({
    dry_run         = false
    dry_run_wallet  = 0
    max_open_trades = 1
    stake_currency  = "USDT"
    stake_amount    = "unlimited"
    timeframe       = "15m"

    exchange = {
      name   = "kraken"
      key    = local.kraken_api_key_value
      secret = local.kraken_api_secret_value

      ccxt_config = {
        enableRateLimit = true
      }
      ccxt_async_config = {
        enableRateLimit = true
      }
      pair_whitelist = [
        "BTC/USDT",
        "ETH/USDT"
      ]
      pair_blacklist = []
    }

    pairlists = [
      { method = "StaticPairList" }
    ]

    entry_pricing = {
      price_side     = "ask"
      use_order_book = false
      fallback       = "last"
    }

    exit_pricing = {
      price_side     = "bid"
      use_order_book = false
      fallback       = "last"
    }

    api_server = {
      enabled           = true
      listen_ip_address = "0.0.0.0"
      listen_port       = 8080
      verbosity         = "error"
      enable_openapi    = false
      username          = local.freqtrade_api_username_value
      password          = local.freqtrade_api_password_value
      jwt_secret_key    = local.freqtrade_jwt_secret_key_value
    }
  })
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
    token = local.cloudflare_token_value
  }
  depends_on = [kubernetes_namespace.ingress]
}

module "cloudflared" {
  count                = var.enable_cloudflared ? 1 : 0
  source               = "./modules/addons/cloudflared_tunnel"
  namespace            = var.ingress_namespace
  existing_secret_name = "cloudflared-token"
  mappings             = var.cloudflare_mappings
  depends_on           = [kubernetes_secret.cloudflared_token]
}

module "freqtrade_bot" {
  for_each = var.enable_bot ? local.bots : {}

  source      = "./modules/apps/freqtrade_bot"
  namespace   = var.bot_namespace
  name        = each.key
  mode        = each.value.live ? "live" : "dry"
  strategy    = each.value.strategy
  secret_ref  = each.value.live ? kubernetes_secret.freqtrade_config[0].metadata[0].name : ""
  persistence = var.bot_persistence
  resources   = var.bot_resources
}

resource "kubernetes_secret" "freqtrade_config" {
  count = var.enable_bot ? 1 : 0

  metadata {
    # one secret per env/cluster
    name      = "${var.bot_namespace}-freqtrade-config"
    namespace = var.bot_namespace
  }

  data = {
    "config.json" = local.freqtrade_config_live
  }

  type = "Opaque"
}

