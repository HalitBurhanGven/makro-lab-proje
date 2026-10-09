#!/usr/bin/python3
"""UNO ile gercek ODF belgeleri ve gomulu LibreOffice Basic makrolari uretir."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

import uno
from com.sun.star.beans import PropertyValue


def prop(name: str, value: object) -> PropertyValue:
    item = PropertyValue()
    item.Name = name
    item.Value = value
    return item


def connect(pipe_name: str):
    local_ctx = uno.getComponentContext()
    resolver = local_ctx.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", local_ctx
    )
    url = f"uno:pipe,name={pipe_name};urp;StarOffice.ComponentContext"
    last_error: Exception | None = None
    for _ in range(80):
        try:
            return resolver.resolve(url)
        except Exception as exc:  # UNO henuz dinlemiyor olabilir.
            last_error = exc
            time.sleep(0.1)
    raise RuntimeError(f"LibreOffice UNO baglantisi kurulamadi: {last_error}")


def add_basic_module(document, source: str) -> None:
    libraries = document.BasicLibraries
    if not libraries.hasByName("Standard"):
        libraries.createLibrary("Standard")
    standard = libraries.getByName("Standard")
    if standard.hasByName("Module1"):
        standard.replaceByName("Module1", source)
    else:
        standard.insertByName("Module1", source)


def bind_on_load(document, macro_name: str) -> None:
    event = (
        prop("EventType", "Script"),
        prop(
            "Script",
            f"vnd.sun.star.script:Standard.Module1.{macro_name}?language=Basic&location=document",
        ),
    )
    document.Events.replaceByName(
        "OnLoad", uno.Any("[]com.sun.star.beans.PropertyValue", event)
    )


def create_document(
    desktop,
    destination: Path,
    title: str,
    body: str,
    macro_source=None,
    on_load=None,
    extra_cells=(),
):
    if destination.exists():
        raise FileExistsError(f"Mevcut dosya ezilmeyecek: {destination}")

    document = desktop.loadComponentFromURL(
        "private:factory/scalc", "_blank", 0, (prop("Hidden", True),)
    )
    try:
        sheet = document.Sheets.getByIndex(0)
        sheet.getCellByPosition(0, 0).String = title
        sheet.getCellByPosition(0, 2).String = body
        for column, row, value in extra_cells:
            sheet.getCellByPosition(column, row).String = value
        document.DocumentProperties.Title = title
        document.DocumentProperties.Subject = "Zararsiz iki kullanicili makro laboratuvari"
        document.DocumentProperties.Description = body
        if macro_source is not None:
            add_basic_module(document, macro_source)
        if on_load is not None:
            bind_on_load(document, on_load)
        document.storeAsURL(destination.resolve().as_uri(), (prop("FilterName", "calc8"),))
    finally:
        document.close(True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()
    project = args.project.resolve()
    output = project / "dist"
    output.mkdir(mode=0o750, parents=True, exist_ok=True)

    expected = [
        output / "kontrol-makrosuz.ods",
        output / "mesaj-manuel.ods",
        output / "mesaj-acilista.ods",
        output / "yetki-deneyi-acilista.ods",
        output / "yetki-deneyi-acilista-v2.ods",
        output / "yetki-deneyi-acilista-v3.ods",
    ]
    message_source = (project / "src" / "MesajMakrosu.bas").read_text(encoding="utf-8")
    probe_source = (project / "src" / "YetkiDeneyi.bas").read_text(encoding="utf-8")
    profile = Path(tempfile.mkdtemp(prefix="makro-lab-uno-", dir="/tmp"))
    pipe_name = f"makro_lab_{os.getpid()}"
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
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    try:
        context = connect(pipe_name)
        service_manager = context.ServiceManager
        desktop = service_manager.createInstanceWithContext("com.sun.star.frame.Desktop", context)
        specifications = [
            (expected[0], "Makrosuz Kontrol Belgesi", "Bu belge makro veya otomatik belge olayi icermez.", None, None),
            (expected[1], "Elle Calistirilan Mesaj Makrosu", "MesajiGoster makrosu yalnizca elle baslatilmalidir.", message_source, None),
            (expected[2], "Acilista Mesaj Makrosu", "AcilistaMesaj makrosu OnLoad olayina baglidir.", message_source, "AcilistaMesaj"),
            (expected[3], "Iki Kullanicili Yetki Deneyi", "AcilistaYetkiDeneyi yalnizca iki laboratuvar hedef dizinine kanit yazmayi dener.", probe_source, "AcilistaYetkiDeneyi"),
            (expected[4], "Iki Kullanicili Yetki Deneyi v2", "AcilistaYetkiDeneyi root ve kullanici hedeflerini bagimsiz dener; sonuclari ayri kaydeder.", probe_source, "AcilistaYetkiDeneyi"),
            (expected[5], "Iki Kullanicili Yetki Deneyi v3", "AcilistaYetkiDeneyi acilmamis dosya taniticisini kapatmadan iki hedefi bagimsiz dener.", probe_source, "AcilistaYetkiDeneyi"),
        ]
        for specification in specifications:
            if specification[0].exists():
                print(f"ATLANDI (mevcut dosya ezilmedi): {specification[0]}")
                continue
            create_document(desktop, *specification)
        desktop.terminate()
    finally:
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.terminate()
            process.wait(timeout=5)
        shutil.rmtree(profile, ignore_errors=True)

    for path in expected:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
