id = "todo-app"
name = "todo-app"
type = "csi"
plugin_id = "nfs"

capability {
  access_mode = "single-node-writer"
  attachment_mode = "file-system"
}