output "vm_ips" {
  value = [for server in hcloud_server.dokploy-for-mern-project : server.ipv4_address]
}

output "floating_ip" {
  description = "Primary floating IP (first one)"
  value = (
    length(var.existing_floating_ip_ids) > 0 ? data.hcloud_floating_ip.existing[0].ip_address : hcloud_floating_ip.ip[0].ip_address
  )
}