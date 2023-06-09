terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {}

data "docker_registry_image" "server_image" {
    name = "ghcr.io/spyicydev/todo-server:latest"
}

resource "docker_image" "server_image" {
    name = data.docker_registry_image.server_image.name
    pull_triggers = [data.docker_registry_image.server_image.sha256_digest]
}

resource "docker_container" "todo-server" {
    name = "todo-server"
    image = docker_image.server_image.image_id
}