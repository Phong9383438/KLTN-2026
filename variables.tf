variable "edge_node_user" {
	description = "Username of Edge device"
	type        = string
	default     = "ubuntu"
}

variable "edge_node_ip" {
	description = "IP Tailscale of Edge device"
	type        = string
}

variable "docker_host" {
	description = "SSH connecting to Docker on Edge Node"
	type        = string
}
