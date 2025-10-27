terraform {
  required_providers {
    digitalocean = { source = "digitalocean/digitalocean" }
    local        = { source = "hashicorp/local" }
  }
}

variable "do_token" {
  type      = string
  sensitive = true
  default   = null
}
variable "name" { type = string }
variable "region" { type = string }
variable "node_size" { type = string }
variable "min_nodes" { type = number }
variable "max_nodes" { type = number }
variable "k8s_version" { type = string }

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_vpc" "vpc" {
  name     = "${var.name}-vpc"
  region   = var.region
  ip_range = "10.42.0.0/16"

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_kubernetes_cluster" "this" {
  name          = var.name
  region        = var.region
  version       = var.k8s_version
  vpc_uuid      = digitalocean_vpc.vpc.id
  auto_upgrade  = true
  surge_upgrade = true

  node_pool {
    name       = "default"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
  }
}

# remove the local_file "kubeconfig" resource

output "kube_host" {
  value = digitalocean_kubernetes_cluster.this.kube_config[0].host
}

output "kube_token" {
  value     = digitalocean_kubernetes_cluster.this.kube_config[0].token
  sensitive = true
}

output "kube_ca" {
  # base64-encoded in DO output; we'll decode at root
  value = digitalocean_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
}
output "cluster_name" { value = digitalocean_kubernetes_cluster.this.name }
