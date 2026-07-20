variable "harness_account_id" {
  type = string
}

variable "harness_delegate_token" {
  type = string
}

variable "harness_delegate_name" {
  type = string
}

variable "harness_deploy_mode" {
  type = string
}

variable "harness_namespace" {
  type = string
}

variable "harness_manager_endpoint" {
  type = string
}

variable "harness_delegate_image" {
  type = string
}

variable "harness_replicas" {
  type    = number
  default = 1
}

variable "harness_upgrader_enabled" {
  type    = bool
  default = false
}

variable "harness_additional_values" {
  default = {
    javaOpts : "-Xms64M"
  }
}

# --- Harness GitOps Agent ---

variable "gitops_namespace" {
  type    = string
  default = "harness-gitops"
}

variable "gitops_org_identifier" {
  type    = string
  default = "default"
}

variable "gitops_project_identifier" {
  type    = string
  default = "default_project"
}

variable "gitops_agent_identifier" {
  type    = string
  default = "harnessagent"
}

variable "gitops_agent_secret" {
  type        = string
  sensitive   = true
  description = "GitOps agent private key / secret from Harness"
}

variable "gitops_redis_password" {
  type        = string
  sensitive   = true
  description = "Redis password for the GitOps Helm chart"
}