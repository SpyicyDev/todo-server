packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source = "github.com/hashicorp/docker"
    }
  }
}

variables {
  bind_port = "80"
  platform = ""
}

source "docker" "image" {
  image  = "ubuntu:focal"
  commit = true
  platform = var.platform
  changes = [
    "ENV BIND_PORT=${var.bind_port}",
    "EXPOSE $BIND_PORT",
    "ENTRYPOINT /tmp/todo-server"
  ]
}

build {
  name = "todo-server"
  sources = [
    "source.docker.image"
  ]
  provisioner "file" {
    source = "todo-server"
    destination = "/tmp/todo-server"
  }
  provisioner "file" {
    source = "ca-certificate.pem"
    destination = "/tmp/ca-certificate.pem"
  }
  provisioner "shell" {
    inline = ["chmod +x /tmp/todo-server"]
  }

  post-processor "docker-tag" {
    repository = "ghcr.io/spyicydev/todo-server"
    tags = ["${var.platform}"]
  }
}

