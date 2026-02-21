Setup i shpejtë për ndërtimin si aplikacion mobil (Capacitor)

Rishikim: skedari i web është kopjuar në `fitness-mobile/web/index.html` (përfshin të gjitha skedarët CSS/JS inline).

1) Parakushtet
- Node.js dhe npm
- Android Studio + SDK (për Android)
- macOS + Xcode (për iOS)

2) Instalimi (Windows / macOS)

```bash
cd %USERPROFILE%\Desktop\fitness-mobile
npm install
npx cap init com.example.fitnessapp FitnessApp --web-dir=web
```

3) Android

```bash
# Shtoni target Android
npx cap add android
# Ngrini web assets (nëse keni proces build, vendosni output në web/)
# Për këtë projekt web është i pranishëm si skedar statik, kështu që rruga web/ është gati.
npx cap copy android
npx cap open android
# Pastaj përdorni Android Studio për të ndërtuar APK/Run në emulator
```

4) iOS (vetëm në macOS)

```bash
npx cap add ios
npx cap copy ios
npx cap open ios
# Përdorni Xcode për të ndërtuar dhe debug
```

5) Ruajtja e të dhënave
- Ky projekt përdor `localStorage` për të ruajtur `fitnessAppUser`, `fitnessAppSurvey`, `fitnessAppProgress`.
- Nuk është nevojitur plugin i veçantë sipas zgjedhjes suaj. Për të përdorur plugin native në të ardhmen, shtoni `@capacitor/storage`.

6) Kujdes
- Për të publikuar në Play Store/App Store duhet të konfiguroni keystore, signing, icona, splash screens.

Nëse dëshironi, unë mund:
- Shtoj `capacitor.config.ts`/`capacitor.config.json` automatikisht,
- Shtoj `@capacitor/storage` dhe kod për migrim nga `localStorage` në Storage plugin,
- Ose krijoj një Git repo dhe commits me skedaret e projektuara.

Cilën nga këto dëshironi të bëj më pas? (Shtoj config, apo bëj udhëzime hap-pas-hapi për Android build?)

---

CI iOS Build (GitHub Actions)

Nëse nuk keni macOS por dëshironi të ndërtoni një `.ipa` për iPhone, mund ta bëni me GitHub Actions (runner macOS). Shtova një workflow shembull në `.github/workflows/ios-build.yml` që:
- instalon varësitë (`npm ci`),
- sinkronizon Capacitor dhe instalon CocoaPods,
- importon certifikatën `.p12` dhe provisioning profile (duhet t'i vendosni si GitHub Secrets),
- krijon `.xcarchive` dhe e eksporton si `.ipa`,
- ngarkon artifact `.ipa` dhe `.xcarchive` për shkarkim.

Sekretet që duhet të shtoni në repo (Settings → Secrets):
- `P12_BASE64` — base64 i skedarit `.p12` (certifikat nënshkrimi). Për ta marrë base64 në Windows PowerShell:

```powershell
$b = [Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\path\to\cert.p12'))
Write-Output $b
```

- `P12_PASSWORD` — fjalëkalimi i certifikatës `.p12`.
- `MOBILEPROVISION_BASE64` — base64 i provisioning profile `.mobileprovision` (ngjashëm si më sipër).
- `EXPORT_METHOD` (opsional) — `app-store`, `ad-hoc`, `development` (default: `ad-hoc`).

Si ta përdorni:
1. Shtoni sekretet në GitHub repo.
2. Bëni push në `main` ose drejtoni manualisht workflow-in nga Actions tab.
3. Pasi workflow të mbarojë, shkarkoni artifact-in `ios-ipa` nga run.

Shënime:
- Kërkohet Apple Developer account për të krijuar provisioning profiles dhe certifikata.
- Nëse dëshironi, unë mund t'ju ndihmoj të krijoj skriptet për t'i konvertuar certifikatat në base64 ose të konfiguroj Fastlane për menaxhim automat të çertifikatave.

PWA (rekomanduar për përdorues pa Mac)

Nëse preferoni të mos përdorni App Store, PWA (Add to Home Screen) është zgjidhja e shkurtër dhe e thjeshtë. Unë kam përfunduar konfigurimin bazë (manifest + service worker). Për ta bërë PWA më profesionale dhe të dukshme në Home Screen, rekomandoj të gjeneroni ikonat si PNG (192x192 dhe 512x512) dhe t'i vendosni në `web/icons/`.

Udhëzime të shpejta për ikonat (Windows):

- Përdorni një imazh burim 1024x1024 (p.sh. `logo.png`) dhe gjeneroni ikonat me ImageMagick (nëse e keni të instaluar):

```powershell
magick convert logo.png -resize 192x192 web\icons\icon-192.png
magick convert logo.png -resize 512x512 web\icons\icon-512.png
```

- Nëse nuk keni ImageMagick: përdorni një nga këto njësitë online për të gjeneruar ikonat dhe shkarkoni ato në `web/icons/`:
	- https://app-manifest.firebaseapp.com/
	- https://realfavicongenerator.net/

Pasi të vendosni ikonat, rifreskoni `web/manifest.json` për të përdorur rrugët relative (`icons/icon-192.png`, `icons/icon-512.png`) në vend të data-URIs (unë kam vendosur placeholder data-URIs për provë). Gjithashtu rihapni URL në Safari dhe zgjidhni Share → Add to Home Screen.

Gjenerimi automatik me logon tuaj (e ngarkuar)

Unë kam shtuar një skript PowerShell që krijon automatikisht ikonat nga imazhi juaj burim. Veproni kështu:

1) Ruani imazhin që ngarkuat më lart si `logo.png` në rrënjën e projektit `c:\Users\User\Desktop\fitness-mobile`.
2) Hapni PowerShell dhe ekzekutoni:

```powershell
cd C:\Users\User\Desktop\fitness-mobile\scripts
.\generate-icons.ps1
```

Skripti krijon `web/icons/icon-192.png` dhe `web/icons/icon-512.png` automatikisht. Pasi të jenë krijuar, rifreskoni faqen në Safari dhe përdorni Share → Add to Home Screen për të instaluar PWA me ikonën tuaj.

Nëse preferoni, mund ta bëj unë këtë hapa këtu (më thoni “bëje ti”) dhe unë do të vendos ikonat në `web/icons/`.

Testi i instalimit në iPhone:

1. Host-oni `web/` në një server të arritshëm për iPhone (GitHub Pages ose `http-server` në makinën tuaj me IP të aksesueshme).
2. Nga Safari në iPhone vizitoni URL-në, hap menunë Share dhe zgjidh `Add to Home Screen`.

Kërkesat dhe kufizimet:
- PWA në iOS nuk mbështet të gjitha API-të native (p.sh. Push Notifications të plota) dhe Safari ka disa kufizime (lidhur me storage dhe background). Megjithatë për përdorim personal dhe shpërndarje jashtë App Store kjo është zgjidhja më e shpejtë.

Publikim me GitHub Pages (rekomanduar)

Workflow i deploy është shtuar në `.github/workflows/deploy-pages.yml` dhe publikon automatikisht folderin `web/`.

Hapat:

1. Krijoni një repo në GitHub dhe bëni push të projektit në branch `main`.
2. Hapni repo në GitHub → `Settings` → `Pages`.
3. Te `Build and deployment`, zgjidhni `Source: GitHub Actions`.
4. Bëni një commit/push (ose `Run workflow`) dhe prisni deploy-in në tab-in `Actions`.
5. URL finale do të jetë zakonisht:
	- `https://<username>.github.io/<repo>/`

Instalimi në iPhone:

1. Hap URL-në e GitHub Pages në Safari.
2. Shtyp `Share` → `Add to Home Screen`.
3. Nëse shfaqet ikona e vjetër, fshije app-in nga Home Screen dhe shtoje prapë.

