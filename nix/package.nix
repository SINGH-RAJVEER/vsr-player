{ lib, stdenv, fetchurl, autoPatchelfHook, qt6, patchelf, ffmpeg_9
, libass, libplacebo, curl, libcdio-paranoia, libdvdnav, mujs
, lcms2, libarchive, luajit, rubberband, libuchardet, zimg, zlib
, alsa-lib, libjack2, pipewire, libpulseaudio, sndio, libcaca
, libdrm, libgbm, libjpeg8, libsixel, wayland
, libxkbcommon, libx11, libxfixes, libxscrnsaver, libxext, libxpresent, libxrandr, libxv, libglvnd, vulkan-loader, libva, libvdpau, cudaPackages_13
, yt-dlp, unzip, coreutils, bash, makeWrapper, fontconfig, freetype, libxml2, zstd
}:

stdenv.mkDerivation (finalAttrs: {
	pname = "vsr-player";
	version = "0.7.1";

	src = fetchurl {
		url = "https://github.com/zhangmq/vsr-player/releases/download/v${finalAttrs.version}/vsr-player-${finalAttrs.version}-linux-x86_64.tar.xz";
		hash = "sha256-bsrO0JOow2PNJ+PAz6htbuNV8QGiiKN2zMQNlwWsADY=";
	};

	# Use the SONAMEs from the release build environment.
	cdioArchive = fetchurl {
		url = "https://archlinux.cachyos.org/repo/extra/os/x86_64/libcdio-2.4.0-1-x86_64.pkg.tar.zst";
		hash = "sha256-vjvzZOJLovyGYuhfiE6ZhcAyTsxGsHh8+CV3vsfLSLA=";
	};
	displayInfoArchive = fetchurl {
		url = "https://archlinux.cachyos.org/repo/extra/os/x86_64/libdisplay-info-0.3.0-1-x86_64.pkg.tar.zst";
		hash = "sha256-B6sUeexecK6hdOLQ40C9k2S1B+108t87/VGzxvQOV4c=";
	};

	blurayArchive = fetchurl {
		url = "https://archlinux.cachyos.org/repo/extra/os/x86_64/libbluray-1.5.1-1-x86_64.pkg.tar.zst";
		sha256 = "69f006d2a282f28fee68b01f617528f04bec475ac67c03e334f03c606b7cb104";
	};

	nativeBuildInputs = [ autoPatchelfHook patchelf makeWrapper zstd qt6.wrapQtAppsHook ];
	buildInputs = [
		stdenv.cc.cc.lib qt6.qtbase qt6.qtdeclarative qt6.qtwayland qt6.qtsvg
		ffmpeg_9 libass libplacebo curl libcdio-paranoia libdvdnav mujs
		lcms2 libarchive luajit rubberband libuchardet zimg zlib
		alsa-lib libjack2 pipewire libpulseaudio sndio libcaca
		libdrm libgbm libjpeg8 libsixel wayland libxkbcommon
		libx11 libxfixes libxscrnsaver libxext
		libxpresent libxrandr libxv
		libglvnd vulkan-loader libva libvdpau cudaPackages_13.cuda_nvrtc fontconfig freetype libxml2
	];

	# The active NixOS NVIDIA driver provides this library.
	autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];
	dontWrapQtApps = true;
	dontStrip = true;
	dontConfigure = true;
	dontBuild = true;

	installPhase = ''
		runHook preInstall

		app="$out/libexec/vsr-player"
		mkdir -p "$out/bin" "$app" "$out/share/applications" "$out/share/doc/vsr-player"
		install -m755 vsr-player mpv-vsr "$app/"
		cp -r translations "$app/"
		mkdir -p "$out/libexec/share/vsr-player"
		cp -r fonts "$out/libexec/share/vsr-player/"
		cp -a lib/vsr-player/libmpv.so.2 lib/vsr-player/libvsr-*.so "$app/"
		${lib.optionalString (qt6.qtbase.version == "6.12.0") ''
			mkdir -p "$app/qt-fixes"
			cp -a lib/vsr-player/libQt6{Gui,Quick}.so.6 "$app/qt-fixes/"
		''}
		tar --zstd -xf "$blurayArchive" -C "$app" --strip-components=2 usr/lib/libbluray.so.4 usr/lib/libbluray.so.4.0.0
		tar --zstd -xf "$cdioArchive" -C "$app" --strip-components=2 usr/lib/libcdio.so.21 usr/lib/libcdio.so.21.0.0
		tar --zstd -xf "$displayInfoArchive" -C "$app" --strip-components=2 usr/lib/libdisplay-info.so.3 usr/lib/libdisplay-info.so.0.3.0
		cp -r licenses COMPONENTS.md "$out/share/doc/vsr-player/"

		substitute data/vsr-player.desktop.in "$out/share/applications/vsr-player.desktop" \
			--replace-fail '@EXEC@' "$out/bin/vsr-player"
		install -Dm644 data/vsr-player.svg "$out/share/icons/hicolor/scalable/apps/vsr-player.svg"
		install -Dm644 data/vsr-player.png "$out/share/icons/hicolor/512x512/apps/vsr-player.png"

		# The release uses unversioned FFmpeg names to support its upstream installer.
		for binary in "$app/mpv-vsr" "$app/libmpv.so.2"; do
			for entry in avcodec:63 avdevice:63 avfilter:12 avformat:63 avutil:61 swresample:7 swscale:10; do
				soname="lib''${entry%:*}.so"
				if patchelf --print-needed "$binary" | grep -Fxq "$soname"; then
					patchelf --replace-needed "$soname" "$soname.''${entry#*:}" "$binary"
				fi
			done
		done

		makeWrapper "${bash}/bin/bash" "$out/bin/vsr-player-install-vfx" \
			--add-flags "${../scripts/install-vfx-nixos.sh}" \
			--prefix PATH : "${lib.makeBinPath [ coreutils curl unzip ]}"

		runHook postInstall
	'';

	preFixup = ''
		addAutoPatchelfSearchPath "$app"
		for program in vsr-player mpv-vsr; do
			makeQtWrapper "$app/$program" "$out/bin/$program" \
				--prefix LD_LIBRARY_PATH : "$app/qt-fixes:/run/opengl-driver/lib" \
				--prefix PATH : "${lib.makeBinPath [ yt-dlp ]}"
		done
	'';

	meta = {
		description = "Video player with NVIDIA VFX super-resolution, frame interpolation and HDR";
		homepage = "https://github.com/zhangmq/vsr-player";
		license = lib.licenses.gpl2Plus;
		mainProgram = "vsr-player";
		platforms = [ "x86_64-linux" ];
	};
})
