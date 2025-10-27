output "cluster_name" { value = module.cluster.cluster_name }

output "kubeconfig_path" { value = local_file.kubeconfig.filename }
