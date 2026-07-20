resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://harness.github.io/gitops-helm/"
  chart            = "gitops-helm"
  namespace        = var.gitops_namespace
  create_namespace = true

  values = [
    file("${path.module}/files/override.yaml"),
    yamlencode({
      harness = {
        identity = {
          accountIdentifier = var.harness_account_id
          orgIdentifier     = var.gitops_org_identifier
          projectIdentifier = var.gitops_project_identifier
          agentIdentifier   = var.gitops_agent_identifier
        }
      }
    }),
  ]

  set_sensitive {
    name  = "harness.secrets.agentSecret"
    value = var.gitops_agent_secret
  }

  set_sensitive {
    name  = "harness.secrets.redisPassword"
    value = var.gitops_redis_password
  }
}
