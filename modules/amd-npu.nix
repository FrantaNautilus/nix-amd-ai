{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.amd.npu;
in {
  options.hardware.amd.npu = {
    enable = lib.mkEnableOption "AMD NPU (AI Engine) support";
  };

  config = lib.mkIf cfg.enable {
    # TODO: install packages, load firmware, set udev rules
  };
}
