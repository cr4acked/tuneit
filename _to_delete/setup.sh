#!/usr/bin/env bash
# One-time project setup: generates the android/ and ios/ platform folders,
# applies the required manifest/plist patches, fetches packages and runs the
# full check suite. Requires Flutter (stable) on PATH.
set -euo pipefail
cd "$(dirname "$0")"

flutter create --platforms=android,ios --org kz.qoldau --project-name tuneit .
python3 platform_patches/apply_patches.py
flutter pub get
flutter analyze
flutter test

echo
echo "Tuneit is ready. Run it with: flutter run"
