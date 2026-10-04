"""Render the upstream static-module list without invoking its build manager."""
import pathlib
import sys
from types import SimpleNamespace

import jinja2

source, destination = map(pathlib.Path, sys.argv[1:])
template = jinja2.Environment(undefined=jinja2.StrictUndefined).from_string(source.read_text())
destination.write_text(template.render(c=SimpleNamespace(kind="python", platform="web")))
