"""Adapt the pinned launcher to a Nix-managed, read-only installation."""
from pathlib import Path

message = "This SDK is managed by Nix. Components and updates must be supplied by renpy-nix; this launcher cannot modify its installation."


def replace_once(filename, before, after):
    path = Path("launcher/game") / filename
    text = path.read_text()
    if text.count(before) != 1:
        raise RuntimeError(f"Launcher patch no longer matches {filename}: {before!r}")
    path.write_text(text.replace(before, after))


def block_label(filename, label):
    before = f"label {label}:\n"
    after = before + f'\n    $ interface.info(_("{message}"), cancel=Jump("front_page"))\n    jump front_page\n'
    replace_once(filename, before, after)


block_label("updater.rpy", "update")
block_label("updater.rpy", "confirm_update")
block_label("android.rpy", "android_installsdk")
replace_once(
    "updater.rpy",
    "    def add_dlc(name, restart=False):\n",
    '    def add_dlc(name, restart=False):\n'
    f'        interface.info(_("{message}"), cancel=Jump("front_page"))\n'
    '        renpy.jump("front_page")\n',
)
replace_once(
    "updater.rpy",
    "    def fetch_update_channels(quiet=True):\n",
    "    def fetch_update_channels(quiet=True):\n        persistent.has_update = False\n        return []\n",
)
replace_once(
    "install.rpy",
    "    def install_from_zip(name, zipglob, patterns):\n",
    '    def install_from_zip(name, zipglob, patterns):\n'
    f'        interface.info(_("{message}"), cancel=Jump("front_page"))\n'
    '        renpy.jump("front_page")\n',
)
for filename, prompt in [
    ("android.rpy", "Before packaging Android apps, you'll need to download RAPT, the Ren'Py Android Packaging Tool. Would you like to download RAPT now?"),
    ("web.rpy", "Before packaging web apps, you'll need to download RenPyWeb, Ren'Py's web support. Would you like to download RenPyWeb now?"),
]:
    before = f'        $ interface.yesno(_("{prompt}"), no=Jump("front_page"))'
    replace_once(filename, before, f'        $ interface.info(_("{message}"), cancel=Jump("front_page"))\n        jump front_page')

replace_once(
    "project.rpy",
    '            tmp = os.path.join(config.renpy_base, "tmp", self.name)',
    '            tmp = os.path.join(tempfile.gettempdir(), "renpy-nix", self.name)',
)
