{
  lib,
  stdenv,
  xrt,
  ...
}:
stdenv.mkDerivation {
  pname = "xrt-plugin-amdxdna";
  version = "0.0.0-placeholder";
  src = builtins.toFile "placeholder" "";
  dontUnpack = true;
  buildInputs = [xrt];
  buildPhase = ''
    echo "xrt-plugin-amdxdna: not yet implemented" >&2
    exit 1
  '';
  meta = {
    description = "XRT plugin for AMD XDNA/AIE NPU";
    license = lib.licenses.asl20;
    platforms = ["x86_64-linux"];
  };
}
