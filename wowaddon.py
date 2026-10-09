#!/usr/bin/env python3
#
# Buffomat Release and Install tool
#

import argparse
import os
import shutil
import subprocess
import sys
import zipfile
from typing import Iterator, Tuple

# Version bumping rules: Begin each new month with <year>.<month>.0 and increase by 1 with every new bump.
VERSION = "2026.10.4"  # year.month.build_num

ADDON_NAME_CLASSIC = "BuffomatClassic"  # Directory and zip name
ADDON_TITLE_CLASSIC = "Buffomat Classic"  # Title field in TOC
ADDON_TITLE_FOREVER = "Buffomat Classic - WoW: Forever (experimental)"

UI_VERSION_CLASSIC = "11508"
UI_VERSION_CLASSIC_TBC = "20506"  # The Burning Crusade
UI_VERSION_CLASSIC_WOTLK = "30402"  # WotLK
UI_VERSION_CLASSIC_CATA = "40402"  # Cataclysm
UI_VERSION_FOREVER = "16001"  # Forever beta; Mainline architecture, level-60 content

COPY_DIRS = ["Src", "Ace3", "Sounds", "Icons", "Textures"]
COPY_FILES = [
    "Bindings.xml",
    "CHANGELOG.md",
    "embeds.xml",
    "LICENSE.txt",
    "README.md",
    "README.Deutsch.txt",
]

# Client TOC suffixes: https://warcraft.wiki.gg/wiki/TOC_format
# Full catalog, including modes this addon does not support. A suffix constant
# alone does not enable a build target. Filenames use AddonName<SUFFIX>.toc.
SUFFIX_STANDARD = "_Standard"  # Midnight excluding other Modern modes
SUFFIX_MISTS = "_Mists"  # Mists of Pandaria Classic
SUFFIX_CATA = "_Cata"  # Cataclysm Classic
SUFFIX_WRATH = "_Wrath"  # Wrath Classic and Titan Reforged
SUFFIX_TBC = "_TBC"  # Burning Crusade Classic and Anniversary
SUFFIX_CAMELOT = "_Camelot"  # WoW: Forever
SUFFIX_VANILLA = "_Vanilla"  # World of Warcraft Classic (Era)
SUFFIX_PLUNDERSTORM = "_Plunderstorm"
SUFFIX_WOWLABS = "_WoWLabs"  # Unknown Modern mode
SUFFIX_WOWHACK = "_WoWHack"  # Unknown Modern mode
SUFFIX_MAINLINE = "_Mainline"  # Midnight, Modern modes, and Forever
SUFFIX_CLASSIC = "_Classic"  # All Classic expansions, not specifically Era

# Emit only supported flavors, with specific selectors and an unsuffixed fallback.
# Do not use the broad _Classic or _Mainline selectors for an Era-only TOC.
CLASSIC_TOC_VARIANTS = (
    ("", UI_VERSION_CLASSIC),
    (SUFFIX_VANILLA, UI_VERSION_CLASSIC),
    (SUFFIX_TBC, UI_VERSION_CLASSIC_TBC),
    (SUFFIX_WRATH, UI_VERSION_CLASSIC_WOTLK),
    (SUFFIX_CATA, UI_VERSION_CLASSIC_CATA),
)


class BuildTool:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.version = VERSION
        self.copy_dirs = COPY_DIRS[:]
        self.copy_files = COPY_FILES[:]
        self.is_forever = args.version == "forever"

        # Camelot TOC is written for every target: Forever ships it as its only
        # TOC, and the combined Classic package carries it alongside the others.
        self.create_toc(
            dst=f"{ADDON_NAME_CLASSIC}{SUFFIX_CAMELOT}.toc",
            ui_version=UI_VERSION_FOREVER,
            title=ADDON_TITLE_FOREVER,
        )

        if self.is_forever:
            # Keep the Classic TOCs intact when alternating between build targets.
            print(
                "Warning: Forever support is experimental and requires in-client testing."
            )
            return

        for suffix, ui_version in CLASSIC_TOC_VARIANTS:
            self.create_toc(
                dst=f"{ADDON_NAME_CLASSIC}{suffix}.toc",
                ui_version=ui_version,
                title=ADDON_TITLE_CLASSIC,
            )

    def package_files(self, toc_name: str) -> Iterator[Tuple[str, str]]:
        """Yield source and packaged filenames for the selected target's TOCs and files.

        Keep the addon folder name unchanged for asset paths and saved variables.
        Both targets include the Camelot TOC. Forever also includes an unsuffixed
        fallback copied from it; Classic keeps its own Era TOC as the fallback.
        """
        for filename in self.copy_files:
            yield filename, filename
        camelot_toc = f"{toc_name}{SUFFIX_CAMELOT}.toc"
        yield camelot_toc, camelot_toc
        if self.is_forever:
            yield camelot_toc, f"{toc_name}.toc"
        else:
            for suffix, _ in CLASSIC_TOC_VARIANTS:
                filename = f"{toc_name}{suffix}.toc"
                yield filename, filename

    def do_install(self, toc_name: str):
        dst_path = f"{self.args.dst}/{toc_name}"

        if os.path.isdir(dst_path):
            print("Warning: Folder already exists, removing!")
            shutil.rmtree(dst_path)

        os.makedirs(dst_path, exist_ok=True)

        print(f"Destination: {dst_path}")

        for copy_dir in self.copy_dirs:
            print(f"Copying directory: {copy_dir}/*")
            shutil.copytree(copy_dir, f"{dst_path}/{copy_dir}")

        for copy_file, packaged_name in self.package_files(toc_name):
            print(f"Copying: {copy_file}")
            shutil.copy(copy_file, f"{dst_path}/{packaged_name}")

    @staticmethod
    def do_zip_add_dir(zip: zipfile.ZipFile, dir: str, toc_name: str):
        """Add a directory to the zipfile, inside TOC_NAME/... subdir"""
        for file in os.listdir(dir):
            file = dir + "/" + file
            print(f"ZIP: Directory {file}/")
            if os.path.isdir(file):
                BuildTool.do_zip_add_dir(zip, dir=file, toc_name=toc_name)
            else:
                zip.write(file, f"{toc_name}/{file}")

    @staticmethod
    def do_zip_add_root_dir(zip: zipfile.ZipFile, dir: str, toc_name: str):
        """Add a directory to the root of the zip file"""
        for file in os.listdir(dir):
            file = dir + "/" + file
            print(f"ZIP: Directory {file}/")
            if os.path.isdir(file):
                BuildTool.do_zip_add_root_dir(zip, dir=file, toc_name=toc_name)
            else:
                zip.write(file, file)

    def do_zip(self, toc_name: str):
        target_suffix = SUFFIX_CAMELOT if self.is_forever else ""
        zip_name = f"{self.args.dst}/{toc_name}{target_suffix}-{VERSION}.zip"

        with zipfile.ZipFile(
            zip_name, "w", zipfile.ZIP_DEFLATED, allowZip64=True
        ) as zip_file:
            # Add deprecation addon to zip
            # BuildTool.do_zip_add_root_dir(zip_file, dir=f"{ADDON_NAME_CLASSIC}TBC", toc_name=toc_name)

            for input_dir in self.copy_dirs:
                BuildTool.do_zip_add_dir(zip_file, dir=input_dir, toc_name=toc_name)

            for input_f, packaged_name in self.package_files(toc_name):
                print(f"ZIP: File {input_f}")
                zip_file.write(input_f, f"{toc_name}/{packaged_name}")

    @staticmethod
    def git_hash() -> str:
        # Call: git rev-parse HEAD
        p = subprocess.check_output(["git", "rev-parse", "HEAD"])
        hash1 = str(p).rstrip("\\n'").lstrip("b'")
        return hash1[:8]

    @staticmethod
    def create_toc(dst: str, ui_version: str, title: str):
        hash1 = BuildTool.git_hash()

        template = open("toc_template.toc", "rt").read()
        template = template.replace("${UI_VERSION}", ui_version)
        template = template.replace("${VERSION}", f"{VERSION}-{hash1}")
        template = template.replace("${ADDON_TITLE}", title)

        with open(dst, "wt") as out_f:
            out_f.write(template)


def main():
    parser = argparse.ArgumentParser(description="Buffomat Release and Install tool")
    parser.add_argument(
        "--dst",
        type=str,
        required=True,
        action="store",
        help="The destination directory where the game Addons will be copied, "
        "or where ZIP will be stored. TOC name will serve as directory "
        "name.",
    )

    parser.add_argument(
        "--version",
        choices=["classic", "tbc", "wotlk", "cata", "forever"],
        help="Select experimental Forever packaging, or the existing combined "
        "Classic/TBC/WotLK/Cata package (default and all other choices).",
    )

    parser.add_argument(
        "command",
        choices=["help", "zip", "install"],
        help="The action to take. ZIP will create an archive. Install will copy",
    )

    args = parser.parse_args(sys.argv[1:])
    print(args)

    if args.command == "install":
        bt = BuildTool(args)
        bt.do_install(toc_name=ADDON_NAME_CLASSIC)

    elif args.command == "zip":
        bt = BuildTool(args)
        bt.do_zip(toc_name=ADDON_NAME_CLASSIC)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
