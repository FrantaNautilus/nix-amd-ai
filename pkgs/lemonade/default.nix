{
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "lemonade";
  version = "0.0.0-placeholder";
  src = builtins.toFile "placeholder" "";
  dontUnpack = true;
  buildPhase = ''
    echo "lemonade: not yet implemented" >&2
    exit 1
  '';
  meta = {
    description = "Lemonade - AMD AI inference server";
    license = lib.licenses.asl20;
    platforms = ["x86_64-linux"];
  };
}
