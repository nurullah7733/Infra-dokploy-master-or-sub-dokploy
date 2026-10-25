# Dokploy Infrastructure on Hetzner

Terraform configuration for provisioning Ubuntu 22.04 servers on Hetzner Cloud and installing Docker and Dokploy with cloud-init. It also sets up floating IPs, a DNS record, firewall rules, Docker log rotation, and 2 GB of swap.

## How it works

```text
Terraform → Hetzner server + firewall + floating IP
          → DNS A record: subdomain.domain → first floating IP
          → cloud-init → Docker + Dokploy + UFW + swap
```

Server resources are defined in `terraform/`. The startup configuration is in `cloud-init/app.yaml`.

## Before you start

- Install Terraform.
- Have a Hetzner Cloud API token and an SSH key already added to your Hetzner project.
- Have a DNS API token compatible with the configured `timohirt/hetznerdns` provider, and an existing DNS zone for your domain.
- Choose a server type available in your selected Hetzner location. Applying this configuration creates billable resources.

## Configuration

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and replace the example values. Start with one location:

```hcl
hcloud_token    = "YOUR_HETZNER_CLOUD_TOKEN"
hetznerdns_token = "YOUR_DNS_API_TOKEN"
ssh_key_name    = "my-existing-ssh-key"
server_type     = "cpx21"
locations       = ["nbg1"]
domain          = "example.com"
subdomain       = "dokploy"

existing_floating_ip_ids       = []
is_master_dokploy              = true
master_dokploy_ssh_public_key  = ""
open_ports                    = []
```

| Variable | What to provide |
| --- | --- |
| `hcloud_token`, `hetznerdns_token` | API tokens for cloud resources and DNS. |
| `ssh_key_name` | Name of an existing SSH key in Hetzner Cloud. |
| `server_type`, `locations` | Server size and location codes. One server is created per list entry. |
| `domain`, `subdomain` | Existing DNS zone and the A record name to create. |
| `existing_floating_ip_ids` | `[]` to create floating IPs, or existing IDs in the same order as `locations`, one per server. |
| `is_master_dokploy` | `true` for a standalone/master setup. With `false`, the startup template also writes the master's SSH public key to root's `authorized_keys`. Both modes install Dokploy. |
| `master_dokploy_ssh_public_key` | Master's public SSH key when `is_master_dokploy = false`. |
| `open_ports` | Extra TCP ports for the Hetzner firewall, for example `[5432, 5050]`. See the UFW limitation below. |

`dokploy_domain` and the `enable_postgres`, `enable_mysql`, `enable_mongo`, and `enable_redis` flags are declared but currently unused. They do not configure a domain or install databases.

## Deploy

From the project root:

```sh
cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Terraform outputs the server IPs as `vm_ips` and the first floating IP as `floating_ip`. Installation continues through cloud-init after the server is created. Connect with `ssh root@<server-ip>` and check completion with:

```sh
cloud-init status --wait
sudo tail -n 100 /var/log/cloud-init-output.log
docker ps
```

After installation, Dokploy's initial interface is expected at `http://<server-ip>:3000`, subject to firewall access. The DNS record alone does not configure the Dokploy dashboard domain or HTTPS.

To remove the resources managed by this configuration, run `terraform destroy` from `terraform/` and review the proposed deletions.

## Current limitations

- Use one location initially: cloud-init currently receives the first floating IP for every server, and DNS points only to that IP. Multi-server networking needs adjustment.
- The cloud firewall allows TCP ports 22, 80, 443, and 3000. UFW explicitly allows 22, 80, and 443, but omits 3000; verify access before relying on the dashboard URL. The custom-port loop also needs correction to apply `open_ports` inside the server.
- Sub-server mode adds an SSH key but does not automatically register the server with a master Dokploy instance. It writes root's `authorized_keys`, so review SSH access before deployment.

Keep API tokens, private keys, real `.tfvars` files, and Terraform state out of Git. Review the configuration before using it in production.
