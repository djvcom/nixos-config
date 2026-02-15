# Kernel and network hardening - see CIS/NIST references
_:

{
  flake.modules.nixos.hardening = {
    boot = {
      kernelModules = [
        "kvm-intel"
        "kvm-amd"
        "iptable_nat"
        "iptable_filter"
      ];
      swraid.mdadmConf = "MAILADDR root";
      kernel.sysctl = {
        # Prevent SYN flood attacks
        "net.ipv4.tcp_syncookies" = 1;

        # Disable ICMP redirects
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;

        # Don't send ICMP redirects
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;

        # Enable reverse path filtering
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;

        # Log martian packets
        "net.ipv4.conf.all.log_martians" = 1;

        # Restrict kernel pointer exposure
        "kernel.kptr_restrict" = 2;

        # Restrict dmesg to root
        "kernel.dmesg_restrict" = 1;

        # Restrict perf_event_open
        "kernel.perf_event_paranoid" = 3;

        # Restrict BPF
        "kernel.unprivileged_bpf_disabled" = 1;
        "net.core.bpf_jit_harden" = 2;
      };
    };
  };
}
