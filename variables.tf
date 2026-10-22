variable "edge_node_user" {
  description = "Username of Edge device"
  type        = string
  default     = "ubuntu"
}

variable "edge_node_ip" {
  description = "IP Tailscale of Edge device"
  type        = string
  default     = "10.0.3.149"
}
