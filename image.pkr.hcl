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

source "docker" "amd64" {
  image  = "ubuntu:focal"
  commit = true
  platform = "linux/amd64"
  changes = [
    "ENV BIND_PORT=${var.bind_port}",
    "EXPOSE $BIND_PORT",
    "ENTRYPOINT /tmp/todo-server"
  ]
}

source "docker" "arm64" {
  image  = "ubuntu:focal"
  commit = true
  platform = "linux/arm64"
  changes = [
    "ENV BIND_PORT=${var.bind_port}",
    "EXPOSE $BIND_PORT",
    "ENTRYPOINT /tmp/todo-server"
  ]
}

build {
  name = "todo-server"
  sources = [
    "source.docker.amd64",
    "source.docker.arm64"
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
    tags = ["${source.name}"]
  }
}

