
# -------- Provider/auth --------
variable "do_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "doppler_do_token_key" {
  type    = string
  default = "DIGITALOCEAN_ACCESS_TOKEN"
}

variable "doppler_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "doppler_project" {
  type    = string
  default = "trade"
}

variable "doppler_config" {
  type    = string
  default = "prod"
}

variable "doppler_cloudflare_token_key" {
  type    = string
  default = "CLOUDFLARE_TUNNEL_TOKEN"
}

# -------- Cluster --------
variable "cluster_name" {
  type    = string
  default = "trade-ams-prod"
}
variable "region" {
  type    = string
  default = "ams3"
}
variable "node_size" {
  type    = string
  default = "s-1vcpu-2gb"
}
variable "min_nodes" {
  type    = number
  default = 1
}
variable "max_nodes" {
  type    = number
  default = 2
}
variable "k8s_version" {
  type    = string
  default = "1.33.1-do.5"
}

# -------- Toggles --------
variable "enable_cloudflared" {
  type    = bool
  default = true
}
variable "use_doppler_for_cloudflared" {
  type    = bool
  default = true
}
variable "use_doppler_for_do" {
  type    = bool
  default = true
}
variable "enable_bot" {
  type    = bool
  default = true
}

# -------- Cloudflared --------
variable "ingress_namespace" {
  type    = string
  default = "ingress"
}

# used only if use_doppler_for_cloudflared = false
variable "cloudflare_tunnel_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "cloudflare_mappings" {
  description = "List of {host, service_name, service_port} to publish via tunnel"
  type        = list(object({ host = string, service_name = string, service_port = number }))
  default = [
    { host = "bot.example.com", service_name = "freqtrade", service_port = 8080 }
  ]
}

# -------- Freqtrade bot --------
variable "bot_namespace" {
  type    = string
  default = "bot-demo"
}

variable "bot_name" {
  type    = string
  default = "bot-demo"
}

variable "bot_strategy" {
  type    = string
  default = "SampleStrategy"
}

variable "bot_persistence" {
  type    = bool
  default = false
}

variable "bot_resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
}
