# MinIO S3-compatible object storage
{ config, ... }:

{
  services.minio = {
    enable = true;
    dataDir = [ "/var/lib/minio/data" ];
    rootCredentialsFile = config.age.secrets.minio-credentials.path;
    consoleAddress = "127.0.0.1:9001";
    listenAddress = "127.0.0.1:9000";
  };
}
