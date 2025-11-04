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

variable "dokploy_domain" {
  type = string
  default = "example.com"
}

variable "subdomain" {
  type = string
  default = "dokploy"
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

variable "master_dokploy_ssh_public_key" {
  type      = string
  default = ""
}

variable "enable_postgres" {
  type      = bool
  default = false
  description = "if need to postgresql public app"
}

variable "enable_mysql" {
  type      = bool
  default = false
  description = "if need to mysql public app"
}

variable "enable_mongo" {
  type      = bool
  default = false
  description = "if need to mongodb public app"
}

variable "enable_redis" {
  type      = bool
  default = false
  description = "if need to redis public app"
}

variable "is_master_dokploy" {
  type      = bool
  default = false
  description = "Its for master or sub dokploy"
}

variable "open_ports" {
  description = "List of extra TCP ports to open (e.g., [5432, 3306, 5050])"
  type        = list(number)
  default     = []
}

 

 