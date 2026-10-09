#!/usr/bin/python3
"""Kali rolunun sectigi zararsiz mesaji gomulu ODF gorev belgesi olarak uretir."""

from __future__ import annotations

import argparse
import base64
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from build_documents import connect, create_document


def validate_message(value: str) -> str:
    if not 1 <= len(value) <= 80:
        raise argparse.ArgumentTypeError("Mesaj 1-80 karakter olmalidir.")
    if not value.isascii() or not value.isprintable():
        raise argparse.ArgumentTypeError("Bu deneyde mesaj yazdirilabilir ASCII olmalidir.")
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--message", required=True, type=validate_message)
    parser.add_argument(
        "--project", type=Path, default=Path("/home/kali/makro-lab-proje")
    )
    args = parser.parse_args()

    project = args.project.resolve()
    destination = project / "dist" / "gorev-deneyi-acilista-v4.ods"
    if destination.exists():
        raise FileExistsError(f"Mevcut dosya ezilmeyecek: {destination}")

    encoded = base64.b64encode(args.message.encode("ascii")).decode("ascii")
    macro_source = (project / "src" / "GorevDeneyi.bas").read_text(encoding="utf-8")
    profile = Path(tempfile.mkdtemp(prefix="makro-lab-gorev-", dir="/tmp"))
    pipe_name = f"makro_lab_gorev_{os.getpid()}"
    command = [
        "/usr/bin/libreoffice",
        "--headless",
        "--nologo",
        "--nodefault",
        "--nofirststartwizard",
        "--norestore",
        f"-env:UserInstallation={profile.as_uri()}",
        f"--accept=pipe,name={pipe_name};urp;StarOffice.ServiceManager",
    ]
    libreoffice_environment = os.environ.copy()
    libreoffice_environment["SAL_USE_VCLPLUGIN"] = "svp"
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=libreoffice_environment,
    )
    try:
        context = connect(pipe_name)
        desktop = context.ServiceManager.createInstanceWithContext(
            "com.sun.star.frame.Desktop", context
        )
        create_document(
            desktop,
            destination,
            "Kali Tarafindan Secilen Zararsiz Gorev",
            "Kali rolunde secilen mesaj ve Base64 karsiligi belgeye gomulmustur. "
            "Acilis makrosu B8 durumunu degistirir ve yalnizca iki "
            "laboratuvar hedefinde makbuz olusturur.",
            macro_source,
            "AcilistaZararsizGorev",
            (
                (0, 5, "GOREV_MESAJI"),
                (1, 5, args.message),
                (0, 6, "GOREV_BASE64"),
                (1, 6, encoded),
                (0, 7, "GOREV_DURUMU"),
                (1, 7, "BEKLIYOR"),
            ),
        )
        desktop.terminate()
    finally:
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.terminate()
            process.wait(timeout=5)
        shutil.rmtree(profile, ignore_errors=True)

    print(f"document={destination}")
    print(f"message={args.message}")
    print(f"base64={encoded}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
