# Providers that use the generated kubeconfig
provider "kubernetes" {
  host                   = module.cluster.kube_host
  token                  = module.cluster.kube_token
  cluster_ca_certificate = base64decode(module.cluster.kube_ca)
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.kube_host
    token                  = module.cluster.kube_token
    cluster_ca_certificate = base64decode(module.cluster.kube_ca)
  }
}
