let
  terminus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPGskDEvecbqILMi3BN755k2pg6S+2ctewH66YWdpX5H";
  dan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHifaRXUcEaoTkf8dJF4qB7V9+VTjYX++fRbOKoCCpC2";
  allKeys = [ terminus dan ];
in
{
  "ssh-key-root.age".publicKeys = allKeys;
  "ssh-key-dan.age".publicKeys = allKeys;
  "git-identity.age".publicKeys = allKeys;
}
