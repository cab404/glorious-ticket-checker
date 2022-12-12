{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    poetry2nix.url = "github:nix-community/poetry2nix";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, poetry2nix }:
    let
      out = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ poetry2nix.overlay ];
          };

          django-qr-code = with pkgs.python3Packages; let
            pname = "django-qr-code";
            version = "3.1.1";
            disabled = pythonOlder "3.7";
          in
          buildPythonPackage {
            inherit pname version;
            propagatedBuildInputs = [
              pydantic
              django
              pytz
              segno
            ];
            checkPhase = ":";
            preCheck = ''
              export DJANGO_SETTINGS_MODULE=demo_site.settings
            '';
            src = fetchPypi {
              inherit pname version;
              sha256 = "sha256-9H3uRja15Ey0aRXhR0fwQ76FbyHl5jWpTEiTntGMeD8=";
            };
          };

          frontend = with pkgs; let
            pname = "frontend";
            version = "0";
          in
          mkYarnPackage {
            src = ./ticket_checker/panel/npm;

            buildPhase = ''
              runHook preBuild

              yarn build --offline

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/panel
              cp deps/static/panel/bundle.js $out/panel
              cp $node_modules/qr-scanner/qr-scanner-worker.min.js $out/panel

              runHook postInstall
            '';

            doDist = false;
          };

          gtchServer = with pkgs; with python3Packages; let
            pname = "gtch";
            version = "0";
          in
          buildPythonPackage {
            inherit pname version;
            src = ./ticket_checker;
            buildInputs = [ makeWrapper ];

            inherit frontend;

            propagatedBuildInputs = [
              django
              django-qr-code
            ];

            format = "other";

            installPhase = ''
              cp -dr --no-preserve='ownership' . $out/
              wrapProgram $out/manage.py \
                --prefix PYTHONPATH : "$PYTHONPATH:$out/thirdpart:"

              cp -R $frontend $out/panel/static
            '';

          };

        in
        {

          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              yarn
              nixpkgs-fmt
              (python3.withPackages (s: with s; [
                django-qr-code
                ipython
                django
              ]))
            ];
          };

          packages = {
            default = gtchServer;
            inherit frontend;
          };
        };
    in
    with utils.lib; eachSystem defaultSystems out // {
      nixosModules.default = import ./module.nix self;
    };

}
