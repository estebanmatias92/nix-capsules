{
  description = "Entorno de desarrollo reproducible para ejemplos Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Helper simple para soportar múltiples arquitecturas (Linux/macOS)
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      forAllSystems = function:
        nixpkgs.lib.genAttrs supportedSystems (system:
          function (import nixpkgs { inherit system; }));
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # Aquí definimos las herramientas que estarán disponibles en el entorno
          packages = with pkgs; [
            statix    # Linter (soluciona tu error ENOENT)
            nil       # LSP (Language Server) para Nix
            alejandra # Formateador de código (opcional, pero recomendado)
          ];

          # Mensaje opcional al entrar al entorno
          shellHook = ''
            echo "Environment loaded: statix, nil, and alejandra are ready."
          '';
        };
      });
    };
}