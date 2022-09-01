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

          gtchServer = with pkgs; with python3Packages; let
              pname = "gtch";
              version = "0";
          in
            buildPythonPackage {
                inherit pname version;
                src = ./ticket_checker;
                buildInputs = [ makeWrapper ];

                propagatedBuildInputs = [
                    django
                    django-qr-code
                ];

                installPhase = ''
                  cp -dr --no-preserve='ownership' . $out/
                  wrapProgram $out/manage.py \
                    --prefix PYTHONPATH : "$PYTHONPATH:$out/thirdpart:"
                '';

            };

        in
        {


          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              yarn
              nixpkgs-fmt
              gtchServer
              (python3.withPackages (s: with s; [
                django-qr-code
                ipython
                django
              ]))
            ];
          };

          packages.default = gtchServer;

        };
    in
    with utils.lib; eachSystem defaultSystems out;

}
