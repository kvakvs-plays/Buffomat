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

VERSION = "2026.1.0"  # year.month.build_num

ADDON_NAME_CLASSIC = "BuffomatClassic"  # Directory and zip name
ADDON_TITLE_CLASSIC = "Buffomat Classic"  # Title field in TOC

UI_VERSION_CLASSIC = "11508"
UI_VERSION_CLASSIC_TBC = "20505"  # The Burning Crusade Prepatch
UI_VERSION_CLASSIC_WOTLK = "30402"  # WotLK
UI_VERSION_CLASSIC_CATA = "40402"  # Cataclysm

COPY_DIRS = ["Src", "Ace3", "Sounds", "Textures"]
COPY_FILES = [
    "Bindings.xml",
    "CHANGELOG.md",
    "embeds.xml",
    "LICENSE.txt",
    "README.md",
    "README.Deutsch.txt",
]

SUFFIX_CLASSIC = "-Classic"  # "_Vanilla"
SUFFIX_TBC = "-BCC"  # "_TBC"
SUFFIX_WRATH = "-WOTLKC"  # "_Wrath"
SUFFIX_CATA = "-Cata"  # "_Cata???"


class BuildTool:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.version = VERSION
        self.copy_dirs = COPY_DIRS[:]
        self.copy_files = COPY_FILES[:]
        self.create_toc(
            dst=f"{ADDON_NAME_CLASSIC}.toc",
            ui_version=UI_VERSION_CLASSIC,
            title=ADDON_TITLE_CLASSIC,
        )
        self.create_toc(
            dst=f"{ADDON_NAME_CLASSIC}{SUFFIX_CLASSIC}.toc",
            ui_version=UI_VERSION_CLASSIC,
            title=ADDON_TITLE_CLASSIC,
        )
        self.create_toc(
            dst=f"{ADDON_NAME_CLASSIC}{SUFFIX_TBC}.toc",
            ui_version=UI_VERSION_CLASSIC_TBC,
            title=ADDON_TITLE_CLASSIC,
        )
        self.create_toc(
            dst=f"{ADDON_NAME_CLASSIC}{SUFFIX_WRATH}.toc",
            ui_version=UI_VERSION_CLASSIC_WOTLK,
            title=ADDON_TITLE_CLASSIC,
        )
        self.create_toc(
            dst=f"{ADDON_NAME_CLASSIC}{SUFFIX_CATA}.toc",
            ui_version=UI_VERSION_CLASSIC_CATA,
            title=ADDON_TITLE_CLASSIC,
        )

    def do_install(self, toc_name: str):
        self.copy_files.append(f"{toc_name}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_CLASSIC}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_TBC}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_WRATH}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_CATA}.toc")

        dst_path = f"{self.args.dst}/{toc_name}"

        if os.path.isdir(dst_path):
            print("Warning: Folder already exists, removing!")
            shutil.rmtree(dst_path)

        os.makedirs(dst_path, exist_ok=True)

        print(f"Destination: {dst_path}")

        for copy_dir in self.copy_dirs:
            print(f"Copying directory: {copy_dir}/*")
            shutil.copytree(copy_dir, f"{dst_path}/{copy_dir}")

        for copy_file in self.copy_files:
            print(f"Copying: {copy_file}")
            shutil.copy(copy_file, f"{dst_path}/{copy_file}")

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
        self.copy_files.append(f"{toc_name}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_CLASSIC}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_TBC}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_WRATH}.toc")
        self.copy_files.append(f"{toc_name}{SUFFIX_CATA}.toc")

        zip_name = f"{self.args.dst}/{toc_name}-{VERSION}.zip"

        with zipfile.ZipFile(
            zip_name, "w", zipfile.ZIP_DEFLATED, allowZip64=True
        ) as zip_file:
            # Add deprecation addon to zip
            # BuildTool.do_zip_add_root_dir(zip_file, dir=f"{ADDON_NAME_CLASSIC}TBC", toc_name=toc_name)

            for input_dir in self.copy_dirs:
                BuildTool.do_zip_add_dir(zip_file, dir=input_dir, toc_name=toc_name)

            for input_f in self.copy_files:
                print(f"ZIP: File {input_f}")
                zip_file.write(input_f, f"{toc_name}/{input_f}")

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
        choices=["classic", "tbc", "wotlk"],
        help="The version to copy or zip: classic, TBC or WotLK",
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
