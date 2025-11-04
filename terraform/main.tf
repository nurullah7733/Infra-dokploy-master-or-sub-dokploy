data "template_file" "cloud_init" {
  count    = length(var.locations)
  template = file("${path.module}/../cloud-init/app.yaml")

  vars = {
    # Use existing floating IP if provided, otherwise use newly created one
    floating_ip = length(var.existing_floating_ip_ids) > 0 ? data.hcloud_floating_ip.existing[0].ip_address : hcloud_floating_ip.ip[0].ip_address
    hetznerdns_token = var.hetznerdns_token
    hostname              = "dokploy-project-${var.locations[count.index]}"
    is_master_dokploy = !var.is_master_dokploy
    master_dokploy_ssh_public_key = var.master_dokploy_ssh_public_key
    open_ports   = join(",", var.open_ports)
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

resource "hcloud_server" "dokploy-project" {
  count         = length(var.locations)
  name          = "dokploy-project-${var.locations[count.index]}-${var.subdomain}"
  server_type   = var.server_type
  image         = "ubuntu-22.04"
  location      = var.locations[count.index]
  ssh_keys    = [data.hcloud_ssh_key.existing.id]  
  user_data = data.template_file.cloud_init[count.index].rendered
  firewall_ids  = [hcloud_firewall.dokploy-project.id]
}


resource "hcloud_firewall" "dokploy-project" {
  name = "allow-http-ssh-dokploy-project-${var.subdomain}"

  # Always allow essential ports
  dynamic "rule" {
    for_each = ["22", "80", "443", "3000"]
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = rule.value
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  }

  # Dynamically open user-specified ports
  dynamic "rule" {
    for_each = var.open_ports
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = tostring(rule.value) # important! hcloud expects string
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  }

  # ICMP (ping)
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
  server_id      = hcloud_server.dokploy-project[count.index].id
}

# Assignment for new floating IPs
resource "hcloud_floating_ip_assignment" "assign_new" {
  count          = length(var.existing_floating_ip_ids) > 0 ? 0 : length(var.locations)
  floating_ip_id = hcloud_floating_ip.ip[count.index].id
  server_id      = hcloud_server.dokploy-project[count.index].id
}



# Local value to determine which floating IP to use for DNS
locals {
  floating_ip_address = length(var.existing_floating_ip_ids) > 0 ? data.hcloud_floating_ip.existing[0].ip_address : hcloud_floating_ip.ip[0].ip_address
}

data "hetznerdns_zone" "main" {
  name = var.domain
}

# dokploy subdomain
resource "hetznerdns_record" "dokploy" {
  zone_id = data.hetznerdns_zone.main.id
  name    = var.subdomain
  type    = "A"
  value   = local.floating_ip_address
  ttl     = 300
}
