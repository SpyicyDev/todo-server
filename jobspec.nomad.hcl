job "todo-app" {
  datacenters = ["dc1"]
  type = "service"

  group "database" {
    network {
      mode = "bridge"
      port "db" {
        to = 5432
      }
    }

    volume "todo-data" {
      type = "csi"
      source = "todo-app"
      read_only = false
      attachment_mode = "file-system"
      access_mode = "single-node-writer"
    }

    service {
      name = "todo-db"
      port = 5432

      connect {
        sidecar_service {}
      }
    }

    task "postgres" {
      driver = "docker"
      
      config {
        image = "postgres:14"
        volumes = [
          "local/init.sql:/docker-entrypoint-initdb.d/init.sql"
        ]
      }

      volume_mount {
        volume = "todo-data"
        destination = "/var/lib/postgresql/data"
        read_only = false
      }

      env {
        POSTGRES_USER = "todo"
        POSTGRES_PASSWORD = "todo123"
        POSTGRES_DB = "todo"
        PGDATA = "/var/lib/postgresql/data/pgdata"
      }

      template {
        data = <<-EOF
          CREATE TABLE IF NOT EXISTS todos(todo_id INT, todo_text VARCHAR(255));
          CREATE TABLE IF NOT EXISTS id(id INT);
          INSERT INTO id (id) VALUES (0) ON CONFLICT DO NOTHING;
        EOF
        destination = "local/init.sql"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  group "api" {
    count = 2

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    service {
      name = "todo-api"
      port = 8080

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "todo-db"
              local_bind_port = 5432
            }
          }
        }
      }

      check {
        type     = "http"
        path     = "/get-todos"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "spyicydev/todo-server:latest"
      }

      env {
        BIND_PORT = "8080"
        DB_ADDRESS = "postgres://todo:todo123@localhost:5432/todo"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }

  group "client" {
    count = 2

    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
    }

    service {
      name = "todo-ui"
      port = 80
      
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.todo-ui.rule=Host(`todo.mackhaymond.co`)"
      ]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "todo-api"
              local_bind_port = 8080
            }
          }
        }
      }

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "ghcr.io/spyicydev/todo-client:latest"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
