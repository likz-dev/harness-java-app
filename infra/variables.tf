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
    type = number 
    default = 1
}

variable "harness_upgrader_enabled" { 
    type = bool
    default = false
}

variable "harness_additional_values" { 
    default = {
        javaOpts: "-Xms64M"
    }
}