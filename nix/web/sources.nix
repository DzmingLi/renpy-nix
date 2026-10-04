{ pkgs }:
let
  # Fetch each vendored upstream tarball independently: unrelated changes to
  # renpy-build do not invalidate the content-addressed library source outputs.
  fetch =
    name: hash:
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/renpy/renpy-build/7bfab40c1174f622f644b24669afd5fb167fbb79/source/${name}";
      inherit name hash;
    };
in
{
  zlib = fetch "zlib-1.3.1.tar.gz" "sha256-mpOyt9/ax3zrpaVYpYDnRmfdb+3kWFuR7vtg8Dty3yM=";
  bzip2 = fetch "bzip2-1.0.8.tar.gz" "sha256-q1oDF27hBtPw+pDjgdpHjdrkBZGBU8yiSOaCzQxKImk=";
  xz = fetch "xz-5.4.2.tar.gz" "sha256-h5R2eavPd8xQnY0bR0IY/Ra3IoHieXNg6QneruGsnQU=";
  python = fetch "Python-3.12.8.tar.xz" "sha256-yQkVe7JewRTlhpEkzCqcSk1MHpV8pP9VPx7caSEBFU4=";
}
