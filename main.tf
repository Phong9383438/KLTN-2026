resource "docker_network" "deception_net" {
	name = "honey_net"
	ipam_config {
		subnet = "10.10.10.0/24"
	}
}

resource "docker_container" "honeypot_cowrie" {
  name    = "honeypot-cowrie"
  image   = "cowrie/cowrie:latest"
  restart = "unless-stopped"

  networks_advanced {
    name         = docker_network.deception_net.name
    ipv4_address = "10.10.10.2"
  }

  ports {
    internal = 2222
    external = 2222
  }

  volumes {
    host_path      = "/home/aira/honeypot_data/cowrie/log"
    container_path = "/cowrie/cowrie-env/var/log/cowrie"
  }
}
