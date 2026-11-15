# AGENTS.md — ChapeletTrainer

## Projet
App iOS SwiftUI (iOS 17+), bundle ID `com.victorlamache.chapelettrainerdev`, équipe `A63WD37CXZ`. Généré via XcodeGen (`project.yml`). CI : `.github/workflows/ios-build.yml`.

## Signature / publication
- Signature dev : Debug = automatique (Apple Development).
- Signature release : Release = manuelle (iPhone Distribution) + profil `ChapeletTrainer AppStore`.
- Certificat .p12 : `C:\Users\victo\Documents\AppleCerts\chapelet_distribution.p12` (mot de passe `Chapelet2026!`).
- Ne pas changer les secrets dev (`BUILD_*`) ; utiliser les secrets `APPSTORE_*` pour la publication.
- `UIRequiresFullScreen: true` (app portrait-only, évite erreur 90474).
- `ITSAppUsesNonExemptEncryption: false` (pas de crypto).

## CI
- `ios-build.yml` : generate → patch scheme → tests → archive (distribution) → export → upload altool.
- Secrets requis : `APPSTORE_BUILD_CERTIFICATE_BASE64`, `APPSTORE_P12_PASSWORD`, `APPSTORE_PROVISIONING_PROFILE_BASE64`, `APPSTORE_KEYCHAIN_PASSWORD`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`.