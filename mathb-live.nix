{
  writeShellApplication,
  sbcl,
  mathb,
}:

let
  sbcl' = sbcl.withPackages (ps: [ ps.hunchentoot ]);
in
writeShellApplication {
  name = "mathb-live";
  runtimeInputs = [ sbcl' ];
  text = ''
    sbcl --load ${mathb}/bin/mathb.lisp --non-interactive
  '';
}
