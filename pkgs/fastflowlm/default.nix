{
  lib,
  stdenv,
  xrt,
  ...
}:
stdenv.mkDerivation {
  pname = "fastflowlm";
  version = "0.0.0-placeholder";
  src = builtins.toFile "placeholder" "";
  dontUnpack = true;
  buildInputs = [xrt];
  buildPhase = ''
    echo "fastflowlm: not yet implemented" >&2
    exit 1
  '';
  meta = {
    description = "FastFlowLM - Fast LLM inference on AMD NPU";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
  };
}
