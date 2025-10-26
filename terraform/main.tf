data "template_file" "cloud_init" {
  count    = length(var.locations)
  template = file("${path.module}/../cloud-init/app.yaml")

  vars = {
    # Use existing floating IP if provided, otherwise use newly created one
    floating_ip = length(var.existing_floating_ip_ids) > 0 ? data.hcloud_floating_ip.existing[0].ip_address : hcloud_floating_ip.ip[0].ip_address
    hetznerdns_token = var.hetznerdns_token
    hostname              = "dokploy-for-mern-project-${var.locations[count.index]}"
  }
}

# Data source for existing floating IPs
data "hcloud_floating_ip" "existing" {
  count = length(var.existing_floating_ip_ids)
  id    = var.existing_floating_ip_ids[count.index]
}


data "hcloud_ssh_key" "existing" {
  name = var.ssh_key_name
}

resource "hcloud_server" "dokploy-for-mern-project" {
  count         = length(var.locations)
  name          = "dokploy-for-mern-project-${var.locations[count.index]}"
  server_type   = var.server_type
  image         = "ubuntu-22.04"
  location      = var.locations[count.index]
  ssh_keys    = [data.hcloud_ssh_key.existing.id]  
  user_data = data.template_file.cloud_init[count.index].rendered
  firewall_ids  = [hcloud_firewall.dokploy-for-mern-project.id]
}

resource "hcloud_firewall" "dokploy-for-mern-project" {
  name = "allow-http-ssh-dokploy-for-mern-project"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  } 

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3000"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
# postgreSQL
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "5432"
    source_ips = ["0.0.0.0/0", "::/0"]
  } 

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
 
}

# Create new floating IPs only if existing ones are not provided
resource "hcloud_floating_ip" "ip" {
  count         = length(var.existing_floating_ip_ids) > 0 ? 0 : length(var.locations)
  type          = "ipv4"
  home_location = var.locations[count.index]
}

# Assignment for existing floating IPs
resource "hcloud_floating_ip_assignment" "assign_existing" {
  count          = length(var.existing_floating_ip_ids)
  floating_ip_id = var.existing_floating_ip_ids[count.index]
  server_id      = hcloud_server.dokploy-for-mern-project[count.index].id
}

# Assignment for new floating IPs
resource "hcloud_floating_ip_assignment" "assign_new" {
  count          = length(var.existing_floating_ip_ids) > 0 ? 0 : length(var.locations)
  floating_ip_id = hcloud_floating_ip.ip[count.index].id
  server_id      = hcloud_server.dokploy-for-mern-project[count.index].id
}



# Local value to determine which floating IP to use for DNS
locals {
  floating_ip_address = length(var.existing_floating_ip_ids) > 0 ? data.hcloud_floating_ip.existing[0].ip_address : hcloud_floating_ip.ip[0].ip_address
}

data "hetznerdns_zone" "main" {
  name = "falktron.com"
}

# dokploy subdomain
resource "hetznerdns_record" "dokploy" {
  zone_id = data.hetznerdns_zone.main.id
  name    = "dokploy"
  type    = "A"
  value   = local.floating_ip_address
  ttl     = 300
}
