{
	description = "VSR Player for NixOS";

	inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

	outputs = { nixpkgs, ... }:
		let
			system = "x86_64-linux";
			pkgs = import nixpkgs {
				inherit system;
				config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "cuda_nvrtc";
			};
		in {
			packages.${system} = rec {
				vsr-player = pkgs.callPackage ./nix/package.nix { };
				default = vsr-player;
			};
		};
}
