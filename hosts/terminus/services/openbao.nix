# OpenBao secrets management (HashiCorp Vault fork)
_:

{
  services.openbao = {
    enable = true;
    settings = {
      ui = true;
      api_addr = "https://bao.djv.sh";
      cluster_addr = "http://127.0.0.1:8201";

      # Listen on localhost only, Traefik handles TLS
      listener.tcp = {
        type = "tcp";
        address = "127.0.0.1:8200";
        tls_disable = true;
      };

      # Raft storage for single-node deployment
      storage.raft = {
        path = "/var/lib/openbao";
        node_id = "terminus";
      };
    };
  };
}
