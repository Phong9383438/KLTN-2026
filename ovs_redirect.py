import subprocess
import argparse

def add_redirect_flow(bridge, attacker_ip, honeypot_ip, dst_port):
    # Block Attacker's IP and redirect it to honeypot
    flow_rule = (
        f"sudo ovs-ofctl add-flow {bridge} "
        f"'priority=100, ip, nw_src={attacker_ip}, tcp, tp_dst={dst_port}, "
        f"actions=mod_nw_dst:{honeypot_ip},normal'"
    )
    try:
        print(f"Executing: {flow_rule}")
        subprocess.run(flow_rule, shell=True, check=True)
        print(f"[SUCCESS] Redirected from {attacker_ip} to {honeypot_ip}:{dst_port}")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bridge", default="br-edge")
    parser.add_argument("--attacker", required=True)
    parser.add_argument("--honeypot", required=True)
    parser.add_argument("--port", default="22")

    args = parser.parse_args()
    add_redirect_flow(args.bridge, args.attacker, args.honeypot, args.port)
