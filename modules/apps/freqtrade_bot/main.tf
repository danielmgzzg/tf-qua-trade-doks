variable "namespace" { type = string }
variable "name" { type = string }
variable "mode" { type = string } # "dry" | "live"
variable "strategy" { type = string }
variable "secret_ref" { type = string }
variable "persistence" { type = bool }
variable "resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
}



resource "helm_release" "bot" {
  name       = var.name
  namespace  = var.namespace
  chart      = "${path.module}/chart"

  values = [yamlencode({
    mode        = var.mode
    strategy    = var.strategy
    secretRef   = var.secret_ref
    persistence = { enabled = var.persistence }
    resources   = var.resources
  })]
}
