terraform {
  backend "http" {
    address        = "https://api.tfstate.dev/github/v1"
    lock_address   = "https://api.tfstate.dev/github/v1/lock"
    unlock_address = "https://api.tfstate.dev/github/v1/lock"
    lock_method    = "PUT"
    unlock_method  = "DELETE"
    username       = "spyicydev/todo-server"
  }
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
  name = "todo-api"
  value = replace(digitalocean_app.todo-server.default_ingress, "https://", "")
  type = "CNAME"
  proxied = true
}

resource "digitalocean_app" "todo-server" {
  spec {
    name = "todo-server"
    region = "nyc1"

    domain {
      name = "todo-api.mackhaymond.co"
    }

    service {
      name = "todo-server"
      instance_count = 1
      http_port = 80
      image {
        registry_type = "DOCKER_HUB"
        registry = "spyicydev"
        repository = "todo-server"
        tag = "latest"
      }
      env {
        key = "DB_ADDRESS"
        value = digitalocean_database_cluster.todo-server-db.uri
      }
      env {
        key = "CA_CERT"
        value = data.digitalocean_database_ca.db.certificate
      }
    }
  }
}

resource "digitalocean_database_cluster" "todo-server-db" {
  name = "todo-server-db"
  engine = "pg"
  version = "14"
  size = "db-s-1vcpu-1gb"
  region = "nyc1"
  node_count = 1
  
  provisioner "local-exec" {
    command = "sleep 10 && psql ${self.uri} -c 'CREATE TABLE todos(todo_id INT, todo_text VARCHAR(255));'"
  }
  provisioner "local-exec" {
    command = "sleep 10 && psql ${self.uri} -c 'CREATE TABLE id(id INT);'"
  }
  provisioner "local-exec" {
    command = "sleep 10 && psql ${self.uri} -c 'INSERT INTO id (id) VALUES (0);'"
  }
}

data "digitalocean_database_ca" "db" {
  cluster_id = digitalocean_database_cluster.todo-server-db.id
}

