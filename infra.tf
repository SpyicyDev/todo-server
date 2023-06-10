terraform {
  required_providers {
    digitalocean  = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

variable "do_token" {
  sensitive = true
  type = string
}

variable "cloudflare_api_token" {
  sensitive = true
  type = string
}

variable "cloudflare_zone_id" {
  sensitive = true
  type = string
}

provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "server" {
  zone_id = var.cloudflare_zone_id
  name = "alt"
  value = digitalocean_app.todo-server.live_url
  type = "CNAME"
}

resource "digitalocean_app" "todo-server" {
  spec {
    name = "todo-server"
    region = "nyc1"

    domain {
      name = "alt.mackhaymond.co"
    }

    service {
      name = "todo-server"
      instance_count = 3
      http_port = 80
      image {
        registry_type = "DOCKER_HUB"
        registry = "spyicydev"
        repository = "todo-server"
        tag = "latest"
      }
    }
  }
}
