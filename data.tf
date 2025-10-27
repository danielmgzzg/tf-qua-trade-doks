resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content  = <<YAML
apiVersion: v1
kind: Config
clusters:
- name: do-cluster
  cluster:
    server: ${module.cluster.kube_host}
    certificate-authority-data: ${module.cluster.kube_ca}
contexts:
- name: do-context
  context:
    cluster: do-cluster
    user: do-user
current-context: do-context
users:
- name: do-user
  user:
    token: ${module.cluster.kube_token}
YAML
}
