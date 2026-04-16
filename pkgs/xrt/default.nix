{
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "xrt";
  version = "0.0.0-placeholder";
  src = builtins.toFile "placeholder" "";
  dontUnpack = true;
  buildPhase = ''
    echo "xrt: not yet implemented" >&2
    exit 1
  '';
  meta = {
    description = "Xilinx Runtime (XRT) for AMD AI Engine";
    license = lib.licenses.asl20;
    platforms = ["x86_64-linux"];
  };
}
