import os;
import sys;
import socket
import jinja2;

backend_nodes = []
existing_entries = []
localhost = socket.gethostbyname(socket.gethostname())

try:
  service_name = os.environ['HAPROXY_SERVICE_NAME_TO_PROXY']
except:
  sys.exit("Could not find service name to proxy. Make sure you set HAPROXY_SERVICE_NAMES_TO_PROXY in ENV.")

try:
  hosts = open("/etc/hosts")
except:
  sys.exit("Could not open /etc/hosts to check dynamic hosts.")

for host in hosts:
  host_entry = host.split()
  if len(host_entry) > 2:
    (host_ip, host_name) = host_entry[0:2]
    if (host_ip not in existing_entries) and (host_name.startswith(service_name)) and (host_ip not in ["0.0.0.0", "127.0.0.1", localhost]):
      existing_entries.append(host_ip)
      backend_nodes.append({'name' : host_name, 'ip' : host_ip})

view_vars = {
  'backend_nodes' : backend_nodes
}

sys.stdout.write(jinja2.Template(sys.stdin.read()).render(view_vars, env=os.environ))
