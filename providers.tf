terraform {
	required_providers {
		docker = {
			source = "kreuzwerker/docker"
		}
	}
}
provider "docker" {
	host = "ssh://${var.edge_node_user}@${var.edge_node_ip}"
}
