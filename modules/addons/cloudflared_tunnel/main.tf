#############################
# variables
#############################
variable "namespace" {
  type = string
}

variable "create_namespace" {
  type    = bool
  default = false # set true only if you want this module to create the namespace
}

variable "existing_secret_name" {
  type = string # Secret in var.namespace with key "token"
}

variable "mappings" {
  type = list(object({
    host              = string
    service_name      = string
    service_port      = number
    service_namespace = optional(string)
  }))
}

#############################
# locals
#############################
locals {
  ingress_rules = concat(
    [
      for m in var.mappings : {
        hostname = m.host
        service = format(
          "http://%s.%s.svc.cluster.local:%d",
          m.service_name,
          coalesce(try(m.service_namespace, null), var.namespace),
          m.service_port
        )
      }
    ],
    [{ service = "http_status:404" }]
  )

  # resolved namespace: when we create it, this becomes a reference and
  # implicitly orders resources; else, it falls back to var.namespace.
  resolved_namespace = coalesce(
    try(kubernetes_namespace.ns[0].metadata[0].name, null),
    var.namespace
  )
}

#############################
# Namespace (optional)
#############################
resource "kubernetes_namespace" "ns" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

#############################
# ConfigMap: /etc/cloudflared/config.yaml
#############################
resource "kubernetes_config_map" "cloudflared_cfg" {
  metadata {
    name      = "cloudflared-config"
    namespace = local.resolved_namespace
  }

  data = {
    "config.yaml" = yamlencode({
      ingress = local.ingress_rules
      metrics = "0.0.0.0:2000"
    })
  }
}

#############################
# Deployment: cloudflare/cloudflared (token run)
#############################
resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = local.resolved_namespace
    labels    = { app = "cloudflared" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "cloudflared" }
    }

    template {
      metadata {
        labels = { app = "cloudflared" }
        annotations = {
          checksum_config = md5(kubernetes_config_map.cloudflared_cfg.data["config.yaml"])
        }
      }

      spec {
        # Optional sysctl; safe to remove if your cluster disallows it
        security_context {
          sysctl {
            name  = "net.ipv4.ping_group_range"
            value = "65532 65532"
          }
        }

        container {
          name  = "cloudflared"
          image = "cloudflare/cloudflared:latest"

          args = [
            "tunnel",
            "--no-autoupdate",
            "run",
            "--token",
            "$(TUNNEL_TOKEN)"
          ]

          env {
            name = "TUNNEL_TOKEN"
            value_from {
              secret_key_ref {
                name = var.existing_secret_name
                key  = "token"
              }
            }
          }

          volume_mount {
            name       = "cfg"
            mount_path = "/etc/cloudflared"
            read_only  = true
          }

          port {
            name           = "metrics"
            container_port = 2000
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/ready"
              port = 2000
            }
            initial_delay_seconds = 20
            period_seconds        = 15
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 2000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }

        volume {
          name = "cfg"
          config_map {
            name = kubernetes_config_map.cloudflared_cfg.metadata[0].name
          }
        }
      }
    }
  }
}
