(lang dune 3.20)

(name valet)

(source (github niols/valet))

(authors "Niols <niols@niols.fr>")
(maintainers "Niols <niols@niols.fr>")

(generate_opam_files true)

(package
 (name valet)
 (synopsis "A PPX rewriter")
 (depends
  (ocaml (>= 5.2))
  (ppxlib (>= 0.32))
  (alcotest :with-test)
  (ppx_inline_test :with-test)))

(formatting (enabled_for dune))
