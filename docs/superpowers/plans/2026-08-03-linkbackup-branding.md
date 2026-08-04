# LinkBackup Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every active CloudDM wordmark with the supplied LinkBackup image, build a matching `clouddm-js.jar`, deploy it first to the designated CloudDM 4.0.1 validation host, and produce a versioned Docker image that can be reused on later hosts.

**Architecture:** Store one cropped, transparent PNG in `frontend/public/assets/img/` and expose its deployment-safe URL through one frontend constant. Vue-rendered logos and both startup loaders use that same asset. Package the rebuilt frontend JAR as a thin Docker layer over the official CloudDM 4.0.1 image, preserving the base image entrypoint and runtime behavior.

**Tech Stack:** Vue 3, Vue CLI 5, Less, Node.js 22.22.1, Gradle, JDK 17+, Docker, PowerShell, SSH.

## Scope And Constraints

- Work on branch `codex/linkbackup-branding`.
- The first rollout target is supplied at execution time through `CDM_DEPLOY_HOST`; do not commit host addresses, SSH credentials, container environment values, or generated inspection files.
- Do not change the second CloudDM host during the first rollout.
- Replace active logos only. Do not rename product copy, API identifiers, package names, database data, or unrelated `CloudDM` text.
- Do not patch minified JavaScript or a JAR in place. Build from repository source so subsequent deployments inherit the branding.
- Do not commit `frontend/node_modules/`, `frontend/dist/`, `frontend/build/`, `package/build/`, image archives, logs, or server backups.
- Keep the existing production container stopped but intact after a successful cutover until browser acceptance is complete.
- The expected interruption is the old-container stop plus new-container startup, normally about one to three minutes. Image construction and backup happen before that interruption.
- The branded JAR and image are tied to CloudDM `4.0.1`. Rebuild against the matching source and base image for every future CloudDM version.

## Expected Repository Changes

**Add:**

- `frontend/public/assets/img/linkbackup-logo.png`
- `frontend/src/const/brand.js`
- `package/docker/alone-branding.Dockerfile`

**Modify:**

- `frontend/src/components/layout/AppBrandLogo.vue`
- `frontend/src/components/DmLogoHeader.vue`
- `frontend/src/App.vue`
- `frontend/public/index.rdp.html`
- `frontend/src/components/widgets/CCLoading.vue`
- `frontend/src/components/widgets/CCEmptyContent.vue`
- `frontend/src/views/home/index.vue`
- `frontend/src/styles/app-shell.less`

**Delete after all references are removed:**

- `frontend/src/assets/logo-clouddm.svg`

No generated file or dependency directory is part of the final Git diff.

---

### Task 1: Establish A Reproducible Build Baseline

**Files:**

- Verify: `AGENTS.md`
- Verify: `frontend/AGENTS.md`
- Verify: `frontend/skill/ui-layout-consistency/SKILL.md`
- Verify: `backend/gradle.properties`
- Verify: `frontend/package-lock.json`

- [x] **Step 1: Confirm branch and a clean starting point**

Run from the repository root:

```powershell
git branch --show-current
git status --short
```

Expected: branch is `codex/linkbackup-branding`; only this plan may be untracked or modified before implementation starts. Stop and preserve any unrelated user changes.

- [x] **Step 2: Use the required Node.js version without changing the global installation**

The currently selected Node.js is older than the repository requirement. Download the official portable Node.js 22.22.1 archive into a user-local tool directory and verify its published checksum:

```powershell
$nodeVersion = 'v22.22.1'
$nodeArchive = "node-$nodeVersion-win-x64.zip"
$nodeToolRoot = Join-Path $env:LOCALAPPDATA 'CodexTools\open-cdm'
$nodeArchivePath = Join-Path $nodeToolRoot $nodeArchive
$nodeExtractRoot = Join-Path $nodeToolRoot $nodeVersion
$nodeBin = Join-Path $nodeExtractRoot "node-$nodeVersion-win-x64"
New-Item -ItemType Directory -Force $nodeToolRoot | Out-Null
Invoke-WebRequest "https://nodejs.org/dist/$nodeVersion/$nodeArchive" -OutFile $nodeArchivePath
Invoke-WebRequest "https://nodejs.org/dist/$nodeVersion/SHASUMS256.txt" -OutFile (Join-Path $nodeToolRoot 'SHASUMS256.txt')
$expectedHash = ((Select-String -LiteralPath (Join-Path $nodeToolRoot 'SHASUMS256.txt') -Pattern "  $nodeArchive$").Line -split '\s+')[0]
$actualHash = (Get-FileHash -LiteralPath $nodeArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) { throw 'Node.js archive checksum mismatch' }
Expand-Archive -LiteralPath $nodeArchivePath -DestinationPath $nodeExtractRoot -Force
$env:Path = "$nodeBin;$env:Path"
node --version
npm --version
```

Expected: `node --version` prints `v22.22.1`.

- [x] **Step 3: Select the available JDK 21 for Gradle**

```powershell
$env:JAVA_HOME = 'E:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
```

Expected: Java reports version 21, satisfying the repository's JDK 17+ requirement.

- [x] **Step 4: Record the relevant source inventory without changing files**

```powershell
rg -n 'logo-clouddm|viewBox="0 0 5897 1024"|AppBrandLogo|DmLogoHeader' frontend/src frontend/public
Select-String -LiteralPath backend/gradle.properties -Pattern '^cg\.clouddm\.main\.version='
```

Expected: active logo references are limited to the shared layout/header components and the two loading templates; the CloudDM version is `4.0.1`.

---

### Task 2: Add One Canonical LinkBackup Asset

**Files:**

- Create: `frontend/public/assets/img/linkbackup-logo.png`
- Create: `frontend/src/const/brand.js`

- [x] **Step 1: Crop the supplied transparent image to its visible bounds**

Use the supplied source image only as an input. The known non-transparent bounds are `x=8..776` and `y=31..264`, producing a `769x234` PNG:

```powershell
Add-Type -AssemblyName System.Drawing
$sourceLogo = 'D:\WorkSpace\CDM-V4\Kingbase\cdm-v4\frontend\node_modules\.pnpm\node_modules\@admin\cdm4\public\assets\img\menu_logo_dark.png'
$targetLogo = Join-Path (Get-Location) 'frontend\public\assets\img\linkbackup-logo.png'
$sourceBitmap = [System.Drawing.Bitmap]::FromFile($sourceLogo)
try {
  $cropRectangle = New-Object System.Drawing.Rectangle(8, 31, 769, 234)
  $targetBitmap = $sourceBitmap.Clone($cropRectangle, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  try {
    $targetBitmap.Save($targetLogo, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $targetBitmap.Dispose()
  }
} finally {
  $sourceBitmap.Dispose()
}
```

- [x] **Step 2: Verify the committed asset, including transparency and dimensions**

```powershell
Add-Type -AssemblyName System.Drawing
$logo = [System.Drawing.Bitmap]::FromFile('frontend\public\assets\img\linkbackup-logo.png')
try {
  if ($logo.Width -ne 769 -or $logo.Height -ne 234) { throw 'Unexpected LinkBackup logo dimensions' }
  if (-not [System.Drawing.Image]::IsAlphaPixelFormat($logo.PixelFormat)) { throw 'LinkBackup logo lost its alpha channel' }
} finally {
  $logo.Dispose()
}
Get-FileHash frontend\public\assets\img\linkbackup-logo.png -Algorithm SHA256
```

Expected: dimension check passes and a SHA-256 hash is printed for later artifact comparison.

- [x] **Step 3: Add one deployment-safe brand URL constant**

Create `frontend/src/const/brand.js`:

```javascript
export const BRAND_NAME = 'LinkBackup';
export const BRAND_LOGO_URL = `${process.env.BASE_URL}assets/img/linkbackup-logo.png`;
```

This keeps Vue-rendered logos correct when CloudDM is hosted below a non-root base URL and prevents path duplication across components.

- [x] **Step 4: Check the focused diff**

```powershell
git status --short
Get-Content frontend/src/const/brand.js
```

Expected: only the new brand constant, PNG, and plan are present at this stage.

---

### Task 3: Replace Every Active Logo Reference

**Files:**

- Modify: `frontend/src/components/layout/AppBrandLogo.vue`
- Modify: `frontend/src/components/DmLogoHeader.vue`
- Modify: `frontend/src/App.vue`
- Modify: `frontend/public/index.rdp.html`
- Modify: `frontend/src/views/home/index.vue`
- Modify: `frontend/src/styles/app-shell.less`
- Delete: `frontend/src/assets/logo-clouddm.svg`

- [x] **Step 1: Update the shared application-shell logo**

In `AppBrandLogo.vue`:

- Import `BRAND_LOGO_URL` from `@/const/brand` and expose it as `brandLogoUrl`.
- Bind the image to `brandLogoUrl` and set `alt="LinkBackup"`.
- Reserve `160px x 49px` for the normal sidebar logo.
- Reserve `92px x 28px` for the compact header logo.
- Keep `object-fit: contain` and left alignment.
- Remove the dark-theme `brightness/invert` filter so the blue/green logo remains full color in both themes.

Stable dimensions prevent the navigation from moving while the PNG loads.

- [x] **Step 2: Update login and initialization headers**

In `DmLogoHeader.vue`:

- Replace the SVG import with `BRAND_LOGO_URL`.
- Return the shared URL from the existing header URL computed property.
- Change the image alternative text to `LinkBackup`.
- Keep the frame width at `184px`, increase its reserved height from `32px` to `56px`, and use `object-fit: contain`.

The initialization page inherits this change because it already uses `DmLogoHeader`; no duplicate implementation is required.

- [x] **Step 3: Replace the Vue-level loading SVG**

In `App.vue`:

- Replace the inline CloudDM `<svg>` in `.loading-page` with an `<img>` bound to `BRAND_LOGO_URL`.
- Add `brandLogoUrl` to component data.
- Set `alt="LinkBackup"`.
- Reserve a `240px` width with `max-width: calc(100vw - 48px)` and `aspect-ratio: 769 / 234`.
- Keep the existing loading animation and page state logic unchanged.

- [x] **Step 4: Replace the pre-Vue HTML loading SVG**

In `frontend/public/index.rdp.html`, replace the inline SVG with:

```html
<img class="loading-logo" src="<%= BASE_URL %>assets/img/linkbackup-logo.png" alt="LinkBackup" />
```

Give `.loading-logo` the same `240px` responsive width and `769 / 234` aspect ratio. Keep the existing pulse animation and loading container unchanged.

- [x] **Step 5: Use compact sizing in the SQL header**

Change the SQL header instance in `frontend/src/views/home/index.vue` to:

```vue
<AppBrandLogo compact />
```

In `frontend/src/styles/app-shell.less`, change `.sql-compact-header__brand` padding to `0`. The existing `58px` brand region centers the `28px` compact logo through flex alignment.

- [x] **Step 6: Remove the obsolete CloudDM SVG after proving it is unused**

```powershell
rg -n "logo-clouddm\.svg" frontend/src frontend/public
```

Expected before deletion: no references. Delete `frontend/src/assets/logo-clouddm.svg`, then run:

```powershell
rg -n 'logo-clouddm|viewBox="0 0 5897 1024"' frontend/src frontend/public
```

Expected: no matches. Other textual uses of `CloudDM` remain because renaming the product is outside this logo-only change.

- [x] **Step 7: Review the source diff before building**

```powershell
git diff --check
git diff -- frontend/src/components/layout/AppBrandLogo.vue frontend/src/components/DmLogoHeader.vue frontend/src/App.vue frontend/public/index.rdp.html frontend/src/views/home/index.vue frontend/src/styles/app-shell.less frontend/src/const/brand.js
```

Expected: no whitespace errors, unrelated formatting, generated files, or business-logic changes.

---

### Task 4: Validate The Frontend And Build `clouddm-js.jar`

**Files:**

- Verify: `frontend/package-lock.json`
- Generated locally only: `frontend/node_modules/`
- Generated locally only: `frontend/dist/`
- Generated locally only: `frontend/build/libs/clouddm-js.jar`

- [x] **Step 1: Install locked dependencies using npm**

```powershell
Push-Location frontend
$env:HUSKY = '0'
npm ci --no-audit --no-fund
Pop-Location
```

Expected: installation succeeds without changing `package-lock.json`.

- [x] **Step 2: Run focused static validation**

```powershell
Push-Location frontend
npm run lint
npm run check-i18n
Pop-Location
```

Expected: both commands exit `0`. No new test class is added because the change is static branding; browser verification covers the user-visible risk.

- [x] **Step 3: Run the repository-mandated web build check**

From a Bash environment with Node.js 22.22.1 and JDK 17+ selected:

```bash
cd package && ./all_build.sh web
```

Expected: `:cgdm-web:processResources` completes successfully. This exact command is required by `frontend/AGENTS.md`.

- [x] **Step 4: Build the frontend JAR on Windows**

```powershell
Push-Location backend
.\gradlew.bat -Pprofile=dev -Ptarget=none -PbuildFrontend=true :cgdm-web:jar --rerun-tasks
Pop-Location
```

Expected artifact: `frontend/build/libs/clouddm-js.jar`.

- [x] **Step 5: Inspect the JAR instead of assuming the asset was packaged**

```powershell
$frontendJar = 'frontend\build\libs\clouddm-js.jar'
if (-not (Test-Path $frontendJar)) { throw 'clouddm-js.jar was not produced' }
& "$env:JAVA_HOME\bin\jar.exe" tf $frontendJar | Select-String 'assets/img/linkbackup-logo.png|index.html'
Get-FileHash $frontendJar -Algorithm SHA256
```

Expected: both `templates/index.html` and `templates/assets/img/linkbackup-logo.png` are listed, followed by the JAR SHA-256.

- [x] **Step 6: Inspect generated references and keep outputs untracked**

```powershell
rg -n "linkbackup-logo\.png" frontend/dist/templates/index.html frontend/dist/templates/js
rg -n --glob '!**/assets/**' --glob '!**/styles/iconfont*' "logo-clouddm|icon-v2-logo-DM" frontend/src frontend/public
git status --short
```

Expected: LinkBackup is referenced, no active source path uses the old logo, and `node_modules`, `dist`, and `build` do not appear in Git status. Dormant legacy logo symbols may remain in generated iconfont bundles.

---

### Task 5: Add And Validate The Reusable Docker Overlay

**Files:**

- Create: `package/docker/alone-branding.Dockerfile`
- Generated locally only: `package/build/linkbackup/clouddm-js.jar`

- [x] **Step 1: Add the thin overlay Dockerfile**

Create `package/docker/alone-branding.Dockerfile`:

```dockerfile
ARG BASE_IMAGE=cloudcanal-registry.cn-shanghai.cr.aliyuncs.com/clougence/cgdm-alone:4.0.1
FROM ${BASE_IMAGE}

COPY --chown=root:root clouddm-js.jar /root/cgdm/alone/libs/clouddm-js.jar
```

The overlay inherits the official image's entrypoint, defaults, database runtime, and architecture while replacing only the frontend JAR.

- [x] **Step 2: Prepare an ignored build context**

```powershell
$brandingContext = 'package\build\linkbackup'
New-Item -ItemType Directory -Force $brandingContext | Out-Null
Copy-Item -LiteralPath 'frontend\build\libs\clouddm-js.jar' -Destination "$brandingContext\clouddm-js.jar" -Force
Copy-Item -LiteralPath 'package\docker\alone-branding.Dockerfile' -Destination "$brandingContext\alone-branding.Dockerfile" -Force
Get-FileHash "$brandingContext\clouddm-js.jar" -Algorithm SHA256
git status --short
```

Expected: the copied JAR hash matches Task 4 and `package/build/` remains absent from Git status.

- [x] **Step 3: Validate the Dockerfile diff**

```powershell
git diff --check
git diff -- package/docker/alone-branding.Dockerfile
```

Expected: the image layer changes only `/root/cgdm/alone/libs/clouddm-js.jar`.

---

### Task 6: Stage The Release And Back Up The Validation Host

**Files on the target host only:**

- Release directory: `/data/cgdm-branding/releases/20260803-linkbackup.1/`
- Backup directory: `/data/cgdm-branding/backups/20260803-linkbackup.1/`
- Root-only environment snapshot: backup directory `cgdm-alone.env`

- [x] **Step 1: Set the target only in the current terminal session**

```powershell
$deployHost = $env:CDM_DEPLOY_HOST
if ([string]::IsNullOrWhiteSpace($deployHost)) { throw 'Set CDM_DEPLOY_HOST in this terminal before deployment' }
$deployTarget = "root@$deployHost"
$releaseId = '20260803-linkbackup.1'
$remoteRelease = "/data/cgdm-branding/releases/$releaseId"
$remoteBackup = "/data/cgdm-branding/backups/$releaseId"
```

Do not write the target address into repository files.

- [x] **Step 2: Reconfirm the live container without printing secrets**

```powershell
ssh $deployTarget "docker inspect --format 'Image={{.Config.Image}} Restart={{.HostConfig.RestartPolicy.Name}} NetworkMode={{.HostConfig.NetworkMode}}' cgdm-alone"
ssh $deployTarget "docker port cgdm-alone"
ssh $deployTarget "docker inspect --format '{{range .Mounts}}{{println .Type .Source .Destination .RW}}{{end}}' cgdm-alone"
ssh $deployTarget "docker info --format '{{.Architecture}}'"
```

Expected baseline: official `cgdm-alone:4.0.1`, restart policy `always`, port `8222`, four `/data/cgdm` bind mounts, and `x86_64` architecture. Stop if these values differ from the reviewed baseline.

- [x] **Step 3: Create private release and backup directories**

```powershell
ssh $deployTarget "install -d -m 700 '$remoteRelease' '$remoteBackup'"
```

- [x] **Step 4: Upload the JAR and Dockerfile, then compare checksums**

```powershell
scp 'package\build\linkbackup\clouddm-js.jar' "${deployTarget}:${remoteRelease}/clouddm-js.jar"
scp 'package\docker\alone-branding.Dockerfile' "${deployTarget}:${remoteRelease}/alone-branding.Dockerfile"
$localJarHash = (Get-FileHash 'package\build\linkbackup\clouddm-js.jar' -Algorithm SHA256).Hash.ToLowerInvariant()
$remoteJarHash = (ssh $deployTarget "sha256sum '$remoteRelease/clouddm-js.jar' | cut -d' ' -f1").Trim()
if ($localJarHash -ne $remoteJarHash) { throw 'Uploaded JAR checksum mismatch' }
```

- [x] **Step 5: Capture rollback material without displaying environment values**

```powershell
ssh $deployTarget "docker inspect cgdm-alone > '$remoteBackup/cgdm-alone.inspect.json'"
ssh $deployTarget "docker cp cgdm-alone:/root/cgdm/alone/libs/clouddm-js.jar '$remoteBackup/clouddm-js.jar'"
ssh $deployTarget "docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' cgdm-alone > '$remoteBackup/cgdm-alone.env' && chmod 600 '$remoteBackup/cgdm-alone.env'"
ssh $deployTarget "sha256sum '$remoteBackup/clouddm-js.jar' > '$remoteBackup/clouddm-js.jar.sha256'"
```

Expected: backup files exist with no environment values printed to the terminal. The secret-bearing environment snapshot stays in the private backup directory, outside the Docker build context. Never copy `cgdm-alone.env` into the repository.

---

### Task 7: Build, Cut Over, And Roll Back Automatically On Failure

**Target image:** `linkbackup/cgdm-alone:4.0.1-linkbackup.1`

- [x] **Step 1: Build the custom image before stopping production**

```powershell
$brandImage = 'linkbackup/cgdm-alone:4.0.1-linkbackup.1'
$baseImage = 'cloudcanal-registry.cn-shanghai.cr.aliyuncs.com/clougence/cgdm-alone:4.0.1'
ssh $deployTarget "docker image inspect '$baseImage' >/dev/null && docker build --build-arg BASE_IMAGE='$baseImage' -t '$brandImage' -f '$remoteRelease/alone-branding.Dockerfile' '$remoteRelease'"
ssh $deployTarget "docker image inspect --format '{{.Id}} {{.Architecture}}' '$brandImage'"
```

Expected: image build succeeds and reports `amd64`/`x86_64`-compatible architecture. The live container is still running.

- [x] **Step 2: Switch containers while retaining the original rollback container**

Run this as one remote shell operation so a failed health check restores the old container immediately:

```powershell
$cutoverScript = @'
set -eu
release_id='20260803-linkbackup.1'
release_dir="/data/cgdm-branding/releases/$release_id"
backup_dir="/data/cgdm-branding/backups/$release_id"
brand_image='linkbackup/cgdm-alone:4.0.1-linkbackup.1'
old_name="cgdm-alone-before-$release_id"

rollback() {
  docker rm -f cgdm-alone >/dev/null 2>&1 || true
  if docker inspect "$old_name" >/dev/null 2>&1; then
    docker update --restart=always "$old_name" >/dev/null || true
    docker rename "$old_name" cgdm-alone
    docker start cgdm-alone >/dev/null
  fi
}

if ! docker stop cgdm-alone; then
  exit 1
fi
if ! docker rename cgdm-alone "$old_name"; then
  docker start cgdm-alone >/dev/null || true
  exit 1
fi
if ! docker update --restart=no "$old_name" >/dev/null; then
  docker rename "$old_name" cgdm-alone
  docker start cgdm-alone >/dev/null || true
  exit 1
fi

if ! docker run -d \
  --name cgdm-alone \
  --restart always \
  --env-file "$backup_dir/cgdm-alone.env" \
  -p 8222:8222 \
  -v /data/cgdm/mysql:/var/lib/mysql \
  -v /data/cgdm/conf:/root/cgdm/alone/conf \
  -v /data/cgdm/logs:/root/cgdm/alone/logs \
  -v /data/cgdm/data:/root/cgdm/alone/data \
  "$brand_image"; then
  rollback
  exit 1
fi

healthy=false
attempt=0
while [ "$attempt" -lt 60 ]; do
  if curl --fail --silent --show-error http://127.0.0.1:8222/ >/dev/null; then
    healthy=true
    break
  fi
  attempt=$((attempt + 1))
  sleep 3
done

if [ "$healthy" != true ]; then
  docker logs --tail 300 cgdm-alone > "$backup_dir/failed-new-container.log" 2>&1 || true
  rollback
  exit 1
fi

inspect_attempt=0
until docker inspect --format 'name={{.Name}} image={{.Config.Image}} status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}}' cgdm-alone; do
  inspect_attempt=$((inspect_attempt + 1))
  if [ "$inspect_attempt" -ge 10 ]; then
    exit 1
  fi
  sleep 1
done
'@
($cutoverScript -replace "`r`n", "`n") | ssh $deployTarget 'sh -s'
```

Expected: the command exits `0`, the new `cgdm-alone` is running with the branded image, and the prior container remains stopped under `cgdm-alone-before-20260803-linkbackup.1`.

- [x] **Step 3: Verify service health and deployment wiring**

```powershell
ssh $deployTarget "curl --fail --silent --show-error http://127.0.0.1:8222/ >/dev/null"
ssh $deployTarget "curl --fail --silent --show-error --head http://127.0.0.1:8222/assets/img/linkbackup-logo.png"
ssh $deployTarget "docker ps --filter name=cgdm-alone --format '{{.Names}} {{.Image}} {{.Status}} {{.Ports}}'"
ssh $deployTarget "docker logs --tail 200 cgdm-alone"
```

Expected: both HTTP checks succeed, the logo response is PNG content, the intended image tag and port are shown, and logs contain no startup failure.

- [x] **Step 4: Exercise restart persistence**

```powershell
ssh $deployTarget "docker restart cgdm-alone >/dev/null"
ssh $deployTarget 'attempt=0; until curl --fail --silent http://127.0.0.1:8222/ >/dev/null; do attempt=$((attempt + 1)); [ "$attempt" -lt 60 ] || exit 1; sleep 3; done'
```

Expected: the same branded container returns HTTP 200 after restart and continues to use all four bind-mounted data directories.

- [x] **Step 5: Retain the original container for manual rollback if browser acceptance fails**

Only run this step when the new service is healthy at HTTP level but fails visual or functional acceptance:

```powershell
$manualRollbackScript = @'
set -eu
release_id='20260803-linkbackup.1'
old_name="cgdm-alone-before-$release_id"
rejected_name="cgdm-alone-linkbackup-rejected-$release_id"

docker stop cgdm-alone
docker update --restart=no cgdm-alone >/dev/null
docker rename cgdm-alone "$rejected_name"
docker update --restart=always "$old_name" >/dev/null
docker rename "$old_name" cgdm-alone
docker start cgdm-alone >/dev/null

attempt=0
until curl --fail --silent http://127.0.0.1:8222/ >/dev/null; do
  attempt=$((attempt + 1))
  [ "$attempt" -lt 60 ] || exit 1
  sleep 3
done
'@
($manualRollbackScript -replace "`r`n", "`n") | ssh $deployTarget 'sh -s'
```

Do not run this while acceptance passes. Expected when needed: the official `4.0.1` container is restored as `cgdm-alone`, and the rejected branded container remains stopped for diagnosis.

---

### Task 8: Perform Browser-Level Acceptance

**Pages:**

- Initial HTML loader before the Vue bundle runs
- Vue application loader during bootstrap
- Login page header
- Initialization header, if the initialization route can be reached without altering system state
- Authenticated normal sidebar
- SQL compact header

- [x] **Step 1: Eliminate browser-cache ambiguity**

Open the validation host in a private window or with browser cache disabled, then perform a hard refresh. Confirm the requested PNG returns `200` in the browser network panel and is not served from an older cache entry.

- [x] **Step 2: Inspect both loading stages**

Use network throttling for the initial HTML loader and delay/observe application bootstrap for the Vue loader. Both must show the LinkBackup logo, preserve aspect ratio, remain centered, and cause no content jump.

- [x] **Step 3: Inspect unauthenticated views**

At desktop `1440x900`, tablet `1024x768`, and mobile `390x844`, verify the login header has no clipping, overlap, or unexpected wrapping. Check both light and dark themes; the logo must retain its original blue/green colors.

- [ ] **Step 4: Inspect authenticated views using the user's existing session**

Verify the normal application sidebar and SQL compact header. Confirm navigation remains clickable, the sidebar menu starts below the logo, the compact title does not overlap the logo, and no header control shifts when the image loads. Do not request, print, or store account credentials.

Also inspect a default `CCLoading`/`CCEmptyContent` state and an existing explicit custom-icon state. The branded image must keep spacing from adjacent text, while explicit custom icons must continue to render unchanged.

- [x] **Step 5: Keep the second host unchanged**

Record acceptance for the validation host only. Rollout to any other host is a separate approval after all six visual locations and restart persistence pass.

---

### Task 9: Export A Reusable Artifact And Document The Upgrade Rule

**Target-host artifact:**

- `/data/cgdm-branding/artifacts/linkbackup-cgdm-alone-4.0.1-linkbackup.1-amd64.tar.gz`
- Matching `.sha256` file

- [x] **Step 1: Export the deployment-verified image**

Exporting the image records the exact artifact deployed to the validation host; it does not complete the authenticated visual acceptance in Task 8 Step 4. Do not promote this artifact to another host until that check is recorded.

```powershell
ssh $deployTarget "install -d -m 700 /data/cgdm-branding/artifacts && docker save -o /data/cgdm-branding/artifacts/linkbackup-cgdm-alone-4.0.1-linkbackup.1-amd64.tar '$brandImage' && gzip -1f /data/cgdm-branding/artifacts/linkbackup-cgdm-alone-4.0.1-linkbackup.1-amd64.tar && cd /data/cgdm-branding/artifacts && sha256sum linkbackup-cgdm-alone-4.0.1-linkbackup.1-amd64.tar.gz > linkbackup-cgdm-alone-4.0.1-linkbackup.1-amd64.tar.gz.sha256"
```

- [x] **Step 2: Verify the archive can be reused safely**

On a future `x86_64` host, verify the checksum before loading:

```bash
sha256sum -c linkbackup-cgdm-alone-4.0.1-linkbackup.1-amd64.tar.gz.sha256
gzip -dc linkbackup-cgdm-alone-4.0.1-linkbackup.1-amd64.tar.gz | docker load
docker image inspect linkbackup/cgdm-alone:4.0.1-linkbackup.1
```

Use the loaded image as a drop-in replacement for the official `4.0.1` image while preserving that host's own environment, ports, networks, and volumes. For a different CPU architecture, rebuild the thin overlay on that architecture from the same JAR and Dockerfile instead of loading this amd64 archive.

- [x] **Step 3: Apply the version-matching rule to future upgrades**

For CloudDM `4.0.2` or any later release:

1. Rebase or merge the branding branch onto that release's source.
2. Re-run Tasks 1 through 5 to produce the matching `clouddm-js-<version>.jar`.
3. Change `BASE_IMAGE` and the custom image tag to the same CloudDM version.
4. Validate on one host before wider rollout.

Never place the `4.0.1` frontend JAR into a different CloudDM base version.

---

### Task 10: Final Source Review And Commit Boundaries

**Files:** all source files listed under Expected Repository Changes.

- [x] **Step 1: Run final repository checks**

```powershell
git diff --check
git status --short
git diff --stat
rg -n 'logo-clouddm|viewBox="0 0 5897 1024"' frontend/src frontend/public
```

Expected: no old active logo signature, no generated outputs, no whitespace errors, and no unrelated changes.

- [ ] **Step 2: Commit the source branding change**

Stage only the plan, PNG, brand constant, Vue/HTML/Less changes, and SVG deletion. Use:

```text
feat(frontend): replace CloudDM logos with LinkBackup branding
```

- [ ] **Step 3: Commit the reusable image layer**

Stage only `package/docker/alone-branding.Dockerfile`. Use:

```text
build(docker): add LinkBackup branding overlay
```

- [ ] **Step 4: Report acceptance and rollback state**

The completion report must include:

- source branch and commit IDs;
- frontend/JAR/image verification results;
- deployed image tag and target-host health result;
- browser views and viewports checked;
- location and SHA-256 of the reusable image archive;
- name of the retained rollback container;
- confirmation that the second host was not changed.

Do not delete the retained rollback container until the user explicitly accepts the validation deployment.
