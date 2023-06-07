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
}

source "docker" "ubuntu" {
  image  = "ubuntu:focal"
  commit = true
  changes = [
    "ENV BIND_PORT=${var.bind_port}",
    "EXPOSE $BIND_PORT",
    "ENTRYPOINT /tmp/todo-server"
  ]
}

build {
  name = "todo-server"
  sources = [
    "source.docker.ubuntu"
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

  post-processors {
    post-processor "docker-tag" {
      repository = "ghcr.io/spyicydev/todo-server"
      tags = ["latest"]
    }
  }
}

