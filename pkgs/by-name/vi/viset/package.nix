{
  lib,
  buildDotnetModule,
  chromium,
  clang,
  dotnetCorePackages,
  fetchFromGitHub,
  openssl,
  zlib,
}:

let
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "getviset";
    repo = "Viset";
    rev = "v${version}";
    hash = "sha256-1wi/5Ndt/Zqn4VH4RP98e5/FnyvUwQEUr46QAN3kkWU=";
  };
in
buildDotnetModule {
  pname = "viset";
  inherit version src;

  projectFile = "src/Viset.Cli/Viset.Cli.fsproj";
  nugetDeps = ./deps.json;
  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  selfContainedBuild = true;
  executables = [ "viset" ];
  postPatch = ''
    rm -f .config/dotnet-tools.json
  '';
  configurePhase = ''
    runHook preConfigure
    # Nix normalizes NuGet archives; packaging/nix/deps.json is the fixed-output build lock.
    dotnet restore src/Viset.Cli/Viset.Cli.fsproj \
      -p:ContinuousIntegrationBuild=true \
      -p:Deterministic=true \
      -p:NuGetAudit=false \
      -p:RestoreLockedMode=false \
      --force-evaluate
    runHook postConfigure
  '';
  dotnetBuildFlags = [
    "-p:PublishAot=true"
    "-p:PublishTrimmed=true"
  ];
  dotnetInstallFlags = [
    "-p:PublishAot=true"
    "-p:PublishTrimmed=true"
  ];

  nativeBuildInputs = [ clang ];
  buildInputs = [ zlib ];
  runtimeDeps = [ openssl ];
  postInstall = ''
    cp browser-lock.toml "$out/lib/viset/browser-lock.toml"
    rm -f "$out/lib/viset/"*.dbg "$out/lib/viset/"*.pdb
    rm -f "$out/lib/viset/libwebpdemux."*
  '';
  makeWrapperArgs = [
    "--set-default"
    "VISET_BROWSER"
    (lib.getExe chromium)
  ];

  meta = {
    description = "Script reproducible browser screenshots and animations";
    homepage = "https://github.com/getviset/Viset";
    license = lib.licenses.mit;
    mainProgram = "viset";
    platforms = lib.platforms.linux;
  };
}
