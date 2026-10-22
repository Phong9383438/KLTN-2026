terraform {
	required_providers {
		docker = {
			source = "kreuzwerker/docker"
		}
	}
}
provider "docker" {
	host = "ssh://aira@127.0.0.1"
}
