# tf with env vars fed from OS CLI

terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.73"
    }
  }
}

locals {
  // Map of pre-named sizes to look up from
  // See https://docs.digitalocean.com/products/droplets/details/pricing/
  // for how a value below maps to a server size & price
  // e.g.:
  # API/CLI Slug	CPUs	Mem(GiB)	SSD (GiB)	Price (hourly)	      Price (monthly)
  # s-1vcpu-1gb	  1     1	        25	      $0.008928571428571428	$6    nano
  # s-1vcpu-2gb	  1	    2	        50	      $0.017857142857142856	$12   nano plus
  # s-2vcpu-2gb	  2	    2	        60	      $0.026785714285714284	$18   micro
  # s-2vcpu-4gb	  2	    4	        80	      $0.03571428571428571	$24   small
  sizes = {
    # API change as of checking on May 22, 2025 -- Now droplet api uses '-amd' or '-intel' at the end.
    # See info with: `doctl compute size list`
    nano      = "s-1vcpu-1gb"
    nano-plus = "s-1vcpu-2gb-amd"
    micro     = "s-2vcpu-2gb"
    small     = "s-2vcpu-4gb"
    medium    = "s-4vcpu-8gb"
    large     = "s-6vcpu-16gb"
    x-large   = "s-8vcpu-32gb"
    xx-large  = "s-16vcpu-64gb"
    xxx-large = "s-24vcpu-128gb"
    maximum   = "s-32vcpu-192gb"
  }
  // Map of regions
  regions = {
    new_york_1    = "nyc1"
    new_york_3    = "nyc3"
    san_francisco = "sfo3"
    amsterdam     = "ams3"
    singapore     = "sgp1"
    london        = "lon1"
    frankfurt     = "fra1"
    toronto       = "tor1"
    india         = "blr1"
  }
  
  # FIXED: Use templatefile() directly in locals instead of data.template_file
  user_data = templatefile("${path.module}/ymlScripts/tf-cloud-config.yml", {
    # For dev login
    LINUX_HUMAN_USERNAME      = var.LINUX_HUMAN_USERNAME
    LINUX_HUMAN_SSHKEY        = var.LINUX_HUMAN_SSHKEY
    # For Github Actions ("GHA") CICD bot to log in
    LINUX_BOTCICDGHA_USERNAME = var.LINUX_BOTCICDGHA_USERNAME
    LINUX_CICDGHA_SSHKEY      = var.LINUX_CICDGHA_SSHKEY
  })
}

provider "digitalocean" {}

###############################################
### Env vars Section -- Human users
variable "LINUX_HUMAN_SSHKEY" {
  type = string
  description = "environment variable for Human Developers devops ssh key"
  default = "Ssh public key to place on server, so it can verify ssh login by Human Dev User (Human Dev User will have matching private key on laptop)"
}
variable "LINUX_HUMAN_USERNAME" {
  type = string
  description = "environment variable for devops user"
  default = "Linx User for Human Dev use"
}

# variable "LINUX_HUMAN_USERPASS" {
#   type = string
#   description = "environment variable for devops user password"
#   default = "Linx User Password for Human Dev use -- for logging into server via SSH"
# }

### Env vars Section -- GHA Cicd bot

variable "LINUX_BOTCICDGHA_USERNAME" {
  type = string
  description = "environment variable for github actions cicd bot user (so it can login to run tasks)"
  default = "Linx User for CICD Bot use"
}
variable "LINUX_CICDGHA_SSHKEY" {
  type = string
  description = "environment variable for CICD Runner bots devops ssh key"
  default = "Ssh public key to place on server, so it can verify ssh login by CICD Bot (bot will have matching private key in the Github Repos secrets)"
}

# the SERVER_NAME is not as important to set via env var... but we will go ahead and do it
variable "LINUX_SERVER_NAME" {
  type = string
  description = "environment variable for devops user"
  default = "blahServerName"
}

variable "SERVER_TAG_DATESTRING" {
  type = string
  description = "simple date to tag the server with"
  default = "default-date-tag"
}

variable "SERVER_TAG_DEPLOY_COLOR" {
  type = string
  description = "color for if blue or green in blue-green deployment"
  default = "default-color-tag"
}

resource "digitalocean_droplet" "droplet" {
  image     = "debian-12-x64"
  name      = var.LINUX_SERVER_NAME
  region    = local.regions.san_francisco
  size      = local.sizes.small
  tags      = [var.SERVER_TAG_DEPLOY_COLOR, var.SERVER_TAG_DATESTRING]
  user_data = local.user_data  # FIXED: Reference the local value instead of data source
}

output "ip_address" {
  value       = digitalocean_droplet.droplet.ipv4_address
  description = "The public IP address of your droplet."
}
output "droplet_size" {
  value       = digitalocean_droplet.droplet.size
  description = "The public IP address of your droplet."
}
output "tf_apply_timestamp" {
  value       = timestamp()
  description = "Timestamp of apply"
}
output "LINUX_HUMAN_SSHKEY" {
  value = var.LINUX_HUMAN_SSHKEY
}
output "LINUX_HUMAN_USERNAME" {
  value = var.LINUX_HUMAN_USERNAME
}

output "LINUX_CICDGHA_SSHKEY" {
  value = var.LINUX_CICDGHA_SSHKEY
}
output "LINUX_BOTCICDGHA_USERNAME" {
  value = var.LINUX_BOTCICDGHA_USERNAME
}
output "LINUX_SERVER_NAME" {
  value = var.LINUX_SERVER_NAME
}

# If you want to make sure the yaml file was properly filled with env vars, you can uncomment this output statement and terraform will show the env vars in situ
# output "template_file_contents" {
#   value = local.user_data
# }

variable "VAULT_1P" {
  type = string
  description = "vault name for uploading IP address"
  default = "1pass vault"
}

variable "ITEM_1P" {
  type = string
  description = "vaults item name for uploading IP address"
  default = "1pass item name (e.g. secure note)"
}

# This works
resource "null_resource" "store_ip_1password" {
  provisioner "local-exec" {
    command = <<-EOT
      op item edit "$TF_VAR_ITEM_1P" --vault "$TF_VAR_VAULT_1P" "LINUX_SERVER_IPADDRESS[text]=${digitalocean_droplet.droplet.ipv4_address}"
    EOT
  }

  # This ensures the script runs every time the IP changes
  triggers = {
    ip_address = digitalocean_droplet.droplet.ipv4_address
  }
}


# added jan 2026
resource "digitalocean_firewall" "my_droplet_firewall_allow_web_ssh" {
  name = "vendure-ecommerce-firewall"

  droplet_ids = [digitalocean_droplet.droplet.id]

  # Inbound: Public web traffic
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Inbound: SSH from anywhere (mobile workflow)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Inbound: ICMP (optional - for monitoring/debugging)
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound: DNS (required)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound: HTTP/HTTPS (required for updates, Docker, APIs)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound: SMTP (required for sending emails)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "587"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "25"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound: ICMP (optional - for debugging)
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
