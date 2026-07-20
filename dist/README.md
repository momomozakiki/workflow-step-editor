# dist/ — release staging

Built, versioned release artifacts are staged **only** here. Everything in this folder except this
`README.md` is gitignored (`/dist/*` + `!/dist/README.md`), so binaries are never committed.

There is no shippable app yet — this folder is a placeholder for when one is added (see
`docs/plan/ROADMAP.md`). At that point, adopt a versioning + checksum packaging script (the
`odb_library` `scripts/package-installers.ps1` template) that derives the version from the shipping
package's `pubspec.yaml` and writes a `.sha256` sidecar.
