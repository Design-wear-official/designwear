# CI/CD

Both repositories have GitHub Actions workflows. They were checked locally (YAML valid, the
same commands run by hand) but **have not yet been seen running on GitHub**: check the
Actions tab after the first push to `main`.

## App repository (`designwear`)

**`ci.yml`:** runs on every push to `main` and every pull request. A newer push cancels the
older run.

| Job | Steps |
|---|---|
| Analyze, test, build web | `flutter analyze`; format check (reports, doesn't block); `flutter test --coverage` (coverage uploaded as an artifact); `flutter build web --release` |
| Build Android (debug) | after the first job: debug APKs for both `external` and `internal` flavours |

The build needs empty `.env` and `.env.local` files (they are bundled assets), so CI creates
placeholders. No secret reaches a pull-request build.

**`release.yml`:** two ways to release, after bumping `version:` in `pubspec.yaml`:

1. Push a tag: `git tag -a v1.2.0 -m v1.2.0 && git push origin v1.2.0`
2. Actions → Release → *Run workflow*, entering `1.2.0` (it creates the tag).

It checks the tag matches `pubspec.yaml`, then builds a **signed Android APK** (`external`) and
a **web bundle**, writes SHA-256 checksums, optionally GPG-signs them, builds release notes
from the commit messages since the previous tag, and attaches everything to a GitHub Release.

Secrets (Settings → Secrets and variables → Actions):

| Secret | Used for |
|---|---|
| `DESIGNWEAR_API_URL` | the only value written into the bundled `.env` |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | release signing (`base64 -w0 upload-keystore.jks`). Missing: the APK is signed with the debug key and the run warns |
| `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE` | optional signatures on the release files |

**`Jenkinsfile`:** mirrors `ci.yml` in a throwaway Docker container (analyze, format, tests, web build).

**`dependabot.yml`:** weekly updates for pub packages and for the actions themselves.

## Server repository (`designwear-backend`)

| Workflow | Does |
|---|---|
| `ci.yml` | `node --test` on Node 20 and 22; builds the Docker image and checks it **refuses to start in production without secrets** |
| `release.yml` | on a `v*.*.*` tag: runs the tests, publishes `ghcr.io/<owner>/designwear-server:<version>` and `:latest`, creates the GitHub Release |

## Branches

`main` is the default branch in both repositories. `master` still holds the previous
versions and is not touched by these workflows.

## Running the same checks by hand

```sh
dart analyze lib test
dart format --set-exit-if-changed lib test
flutter test --concurrency=1
cd ../designwear-server && node --test
```
