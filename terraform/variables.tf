variable "environment" {
  type        = string
  description = "Deployment environment (dev, qa, prod)"
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "project" {
  type        = string
  description = "Project short name"
  default     = "genai"
}

variable "owner" {
  type        = string
  description = "Owner tag"
  default     = "platform-team"
}

# Networking
variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

variable "aks_subnet_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "pe_subnet_cidr" {
  type        = string
  description = "Private endpoints subnet"
  default     = "10.2.0.0/24"
}

variable "appgw_subnet_cidr" {
  type    = string
  default = "10.3.0.0/24"
}

# AKS
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "system_node_count" {
  type    = number
  default = 3
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "user_node_count" {
  type    = number
  default = 2
}

variable "user_node_vm_size" {
  type    = string
  default = "Standard_D8s_v5"
}

variable "user_node_max_count" {
  type    = number
  default = 10
}

# OpenAI
variable "openai_sku" {
  type    = string
  default = "S0"
}

variable "gpt4o_capacity" {
  type    = number
  default = 30
}

variable "embedding_capacity" {
  type    = number
  default = 30
}

# AI Search
variable "search_sku" {
  type    = string
  default = "standard"
}

# Tags
variable "additional_tags" {
  type    = map(string)
  default = {}
}
