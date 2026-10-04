init python:
    import PIL.Image
    assert PIL.Image.new("RGB", (2, 3)).size == (2, 3)

label start:
    "An existing nixpkgs Python package is available to this game."
    return
