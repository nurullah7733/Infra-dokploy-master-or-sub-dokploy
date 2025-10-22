variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key_name" {
  type = string
}

variable "server_type" {
  type = string
}

variable "domain" {
  type = string
  default = "example.com"
}

variable "locations" {
  type = list(string)
  default = ["fsn1", "hel1", "nbg1", "sgp1"]
}

variable "existing_floating_ip_ids" {
  description = "List of existing floating IP IDs to use instead of creating new ones"
  type        = list(string)
  default     = []
}

variable "hetznerdns_token" {
  type      = string
  sensitive = true
}

# variable "monitoring_vm_ip" {
#  type      = string
#  sensitive = true
#  default = []
# }

 