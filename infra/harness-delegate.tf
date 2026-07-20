module "delegate" {
  source = "harness/harness-delegate/kubernetes"
  version = "0.2.3"

  account_id = var.harness_account_id
  delegate_token = var.harness_delegate_token
  delegate_name = var.harness_delegate_name
  deploy_mode = var.harness_deploy_mode
  namespace = var.harness_namespace
  manager_endpoint = var.harness_manager_endpoint
  delegate_image = var.harness_delegate_image
  replicas = var.harness_replicas
  upgrader_enabled = var.harness_upgrader_enabled
  values = yamlencode(var.harness_additional_values)
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}