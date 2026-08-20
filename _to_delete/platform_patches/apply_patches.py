#!/usr/bin/env python3
"""Applies the two platform edits Tuneit needs after `flutter create`:

1. Android: add RECORD_AUDIO permission. INTERNET is deliberately NOT added
   to the main manifest — its absence is a technical guarantee that the
   release build is offline-only.
2. iOS: add NSMicrophoneUsageDescription.

Run from the project root: python3 platform_patches/apply_patches.py
"""
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MIC_PERMISSION = '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n'

MIC_USAGE = (
    "Микрофон нужен, чтобы слышать звук струны и показывать точность "
    "настройки. Запись никуда не отправляется и не сохраняется. / "
    "The microphone is used to hear the string and show tuning accuracy. "
    "Audio is never sent anywhere or stored."
)


def patch_android():
    path = os.path.join(ROOT, "android", "app", "src", "main", "AndroidManifest.xml")
    if not os.path.exists(path):
        print(f"skip (not found): {path}")
        return
    with io.open(path, encoding="utf-8") as f:
        text = f.read()
    if "RECORD_AUDIO" in text:
        print("android: RECORD_AUDIO already present")
        return
    marker = text.index(">", text.index("<manifest")) + 1
    text = text[:marker] + "\n" + MIC_PERMISSION + text[marker:]
    with io.open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("android: added RECORD_AUDIO")


def patch_ios():
    path = os.path.join(ROOT, "ios", "Runner", "Info.plist")
    if not os.path.exists(path):
        print(f"skip (not found): {path}")
        return
    with io.open(path, encoding="utf-8") as f:
        text = f.read()
    if "NSMicrophoneUsageDescription" in text:
        print("ios: NSMicrophoneUsageDescription already present")
        return
    entry = (
        "\t<key>NSMicrophoneUsageDescription</key>\n"
        f"\t<string>{MIC_USAGE}</string>\n"
    )
    marker = text.index("<dict>") + len("<dict>")
    text = text[:marker] + "\n" + entry + text[marker:]
    with io.open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("ios: added NSMicrophoneUsageDescription")


if __name__ == "__main__":
    patch_android()
    patch_ios()
    print("done")
    sys.exit(0)
