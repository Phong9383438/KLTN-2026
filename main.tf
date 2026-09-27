resource "docker_image" "honeypot_image" {
	name		= "nginx:alpine"
	keep_locally	= false
}

resource "docker_network" "deception_net" {
	name = "honey_net"
	ipam_config {
		subnet = "10.10.10.0/24"
	}
}

resource "docker_container" "honeypot_container" {
	image = docker_image.honeypot_image.image_id
	name  = "base_honey_node"

	networks_advanced {
		name		= docker_network.deception_net.name
		ipv4_address	= "10.10.10.5"
	}
	ports {
		internal = 80
		external = 8080
	}
}

