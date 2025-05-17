{
  lib,
  stdenv,
  fetchFromGitHub,
}:

let
  texmeSrc = fetchFromGitHub {
    owner = "susam";
    repo = "texme";
    rev = "1.2.0";
    hash = "sha256-rbO+uKL4QkYnjIov4amAMZBZOzjI58ruXhf97XtJEio=";
  };
  markedSrc = fetchFromGitHub {
    owner = "markedjs";
    repo = "marked";
    rev = "v4.1.0";
    hash = "sha256-FfHMarphpE8IUvOgt2hddNahkMlna8dDB/F1F79X3IE=";
  };
  mathjaxSrc = fetchFromGitHub {
    owner = "mathjax";
    repo = "mathjax";
    rev = "3.2.2";
    hash = "sha256-RIHI2qigotGqbwO09rUfmjkYzmkhYeEX+4B/F+Q6094=";
  };
in
stdenv.mkDerivation rec {
  pname = "mathb";
  version = "1.4.1";
  src = ./.;

  buildPhase = ''
    runHook preBuild

    mkdir -p _live/css/ _live/js/
    cp -R web/css/* _live/css/
    cp -R web/js/* _live/js/
    cp -R web/img/* _live/

    cp -R ${texmeSrc} _live/js/texme
    cp -R ${markedSrc} _live/js/marked
    cp -R ${mathjaxSrc} _live/js/mathjax

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/dist

    cp -r meta $out/

    cp -r web $out/dist/
    cp -r _live $out/dist/

    cp mathb.lisp $out/bin

    runHook postInstall
  '';

  meta = {
    description = "Mathematics pastebin software that powered MathB.in from 2012 to 2025";
    homepage = "https://github.com/susam/mathb";
    changelog = "https://github.com/susam/mathb/blob/${src.rev}/CHANGES.md";
    license = lib.licenses.mit;
    mainProgram = "mathb";
    platforms = lib.platforms.all;
  };
}
