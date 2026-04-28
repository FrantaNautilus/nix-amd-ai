{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  python3,
  jq,
  nlohmann_json,
  cli11,
  curl,
  zstd,
  brotli,
  httplib,
  libwebsockets,
  openssl,
  systemd,
  libcap,
  libdrm,
  fastflowlm,
  llama-cpp-rocm,
  llama-cpp-vulkan,
}: stdenv.mkDerivation rec {
  pname = "lemonade";
  version = "10.3.0";

  src = fetchFromGitHub {
    owner = "lemonade-sdk";
    repo = "lemonade";
    rev = "v${version}";
    hash = "sha256-IQE8E/88yI8MoqyTvoDSNjbPX9F7yW2ckne2PaDewxk=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python3
    jq
  ];

  buildInputs = [
    nlohmann_json
    cli11
    curl
    zstd
    brotli
    httplib
    libwebsockets
    openssl
    systemd
    libcap
    libdrm
  ];

  # nixpkgs ships httplib as `httplib.pc`, but lemonade's CMakeLists looks for
  # `cpp-httplib.pc` via pkg_check_modules. Synthesize an alias .pc file and add
  # it to PKG_CONFIG_PATH so USE_SYSTEM_HTTPLIB takes the system path instead of
  # falling through to FetchContent (which requires network and breaks the
  # nix sandbox).
  preConfigure = ''
    mkdir -p $TMPDIR/pc-shim
    cat > $TMPDIR/pc-shim/cpp-httplib.pc <<EOF
    prefix=${httplib}
    includedir=${httplib}/include
    Name: cpp-httplib
    Description: C++ header-only HTTP/HTTPS server and client library (alias for httplib)
    Version: ${httplib.version}
    Cflags: -I${httplib}/include
    EOF
    export PKG_CONFIG_PATH=$TMPDIR/pc-shim:$PKG_CONFIG_PATH
  '';

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
    (lib.cmakeBool "BUILD_WEB_APP" false)
    (lib.cmakeBool "BUILD_TAURI_APP" false)
    (lib.cmakeBool "REQUIRE_LINUX_TRAY" false)
  ];

  # Patch fastflowlm + llama-cpp backend version pins in resources, matching
  # what the RPM packaging used to do — keeps lemonade's "installed vs needs
  # update" check satisfied so it doesn't try to download backends at runtime.
  postPatch = ''
    # Lemonade's CMakeLists assumes Debian's compiled libcpp-httplib.so
    # (target name `cpp-httplib`); nixpkgs ships httplib header-only, so the
    # link of -lcpp-httplib fails. Header-only cpp-httplib doesn't need a
    # link entry — the inline functions are emitted into our own .o files —
    # so use ''${HTTPLIB_LIBRARIES} (empty under our header-only .pc shim)
    # instead of the literal `cpp-httplib` target name.
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'target_link_libraries(lemonade-server-core PUBLIC cpp-httplib)' \
        'target_link_libraries(lemonade-server-core PUBLIC ''${HTTPLIB_LIBRARIES})'
    substituteInPlace src/cpp/cli/CMakeLists.txt \
      --replace-fail \
        'target_link_libraries(lemonade PRIVATE cpp-httplib)' \
        'target_link_libraries(lemonade PRIVATE ''${HTTPLIB_LIBRARIES})'
    substituteInPlace src/cpp/legacy-cli/CMakeLists.txt \
      --replace-fail \
        'target_link_libraries(lemonade-server PRIVATE cpp-httplib)' \
        'target_link_libraries(lemonade-server PRIVATE ''${HTTPLIB_LIBRARIES})'

    # Three install(CODE ...) blocks in cli, legacy-cli, and the top-level
    # CMakeLists try to symlink binaries / units into /usr/bin and
    # /usr/lib/systemd/system via $ENV{DESTDIR} — designed for Debian's
    # DESTDIR-staged build. In Nix, DESTDIR is unset and CMAKE_INSTALL_PREFIX
    # is $out, so $ENV{DESTDIR}/usr/bin resolves to /usr/bin, which the
    # sandbox refuses. Drop those symlink blocks; the binaries and unit live
    # at $out/{bin,lib/systemd/system}/ and the NixOS module wires them in.
    sed -i '/Create symlink in standard bin path only if not installing to/,/^endif()$/d' \
      src/cpp/cli/CMakeLists.txt \
      src/cpp/legacy-cli/CMakeLists.txt
    sed -i '/Create symlink in standard systemd search path only if not installing to/,/^    endif()$/d' CMakeLists.txt

    # secrets.conf install rule writes to absolute /etc/lemonade/conf.d. The
    # NixOS module is what owns /etc, not us — relocate the template under
    # $out so it ships with the derivation but doesn't try to populate /etc.
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'DESTINATION /etc/lemonade/conf.d' \
        'DESTINATION share/lemonade/conf.d.example'

    if [ -f src/cpp/resources/backend_versions.json ]; then
      jq '.flm.npu = "v${fastflowlm.version}"
          | .llamacpp.rocm = "b${llama-cpp-rocm.version}"
          | .llamacpp.vulkan = "b${llama-cpp-vulkan.version}"' \
        src/cpp/resources/backend_versions.json > src/cpp/resources/backend_versions.json.tmp
      mv src/cpp/resources/backend_versions.json.tmp src/cpp/resources/backend_versions.json
    fi
  '';

  meta = {
    description = "Local AI server with OpenAI-compatible API for NPU/GPU inference (built from source)";
    homepage = "https://github.com/lemonade-sdk/lemonade";
    license = lib.licenses.asl20;
    platforms = ["x86_64-linux"];
    mainProgram = "lemond";
  };
}
