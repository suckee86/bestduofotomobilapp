# Best Duo Fotó mobilapp

Flutter/Dart alkalmazás Androidra és iOS-re, a Best Duo fotórendelő sötét–narancs arculatával és eredeti logójával.

## Elkészült funkciók

- Firebase Authentication Google-belépéssel, iOS-en Apple-belépéssel
- látványos, fotós kezdőoldal gyorsműveletekkel
- a `https://bestduo.hu/onlinefoto/` fotórendelő alkalmazáson belüli WebView-ban
- a belépett felhasználó e-mail-címének automatikus előtöltése a fotórendelőben
- üzletadatok, közvetlen hívás, e-mail, nyitvatartás és interaktív térkép
- Google Térkép útvonaltervezés
- Firebase Cloud Messaging tokenkezelés és alkalmazáson belüli értesítés
- Firestore-alapú hír- és ajánlatlista
- publikált hírekből automatikus push-t küldő Cloud Function
- kijelentkezés és fióktörlés
- saját Android/iOS alkalmazásikon

## Helyi futtatás

```powershell
flutter pub get
flutter run
```

Ellenőrzések:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Az iOS buildhez macOS, Xcode és CocoaPods szükséges:

```bash
cd ios
pod install
cd ..
flutter build ios
```

Az alkalmazásazonosítók a kapott Firebase-fájlokhoz igazodnak:

- Android: `hu.bestduo.app`
- iOS: `hu.bestduo.foto`
- Firebase projekt: `bestduomobilapp`

## Firebase: kötelező beállítások

### 1. Google-belépés és SHA ujjlenyomatok

A jelenlegi `google-services.json` még nem tartalmaz Android OAuth klienst (`client_type: 1`), ezért az Android Google-belépéshez ezt be kell fejezni.

Az ezen a fejlesztőgépen létrehozott debug kulcs ujjlenyomatai:

```text
SHA-1:   29:84:E4:C7:EF:66:AB:79:4D:E7:DD:3B:89:F5:89:56:27:15:27:0D
SHA-256: D4:74:AB:6C:E4:90:3D:2F:1E:7B:53:22:B7:1D:5E:87:04:AA:78:47:F0:61:7E:DB:C1:0D:D8:15:22:FA:89:3F
```

Felvétel:

1. Firebase Console → Project settings → General → Your apps.
2. Válaszd a `hu.bestduo.app` Android appot.
3. Add fingerprint: először SHA-1, majd SHA-256.
4. Authentication → Sign-in method alatt engedélyezd a Google providert.
5. Töltsd le újra a `google-services.json` fájlt, és cseréld le vele a gyökérben, valamint az `android/app/` mappában lévő példányt.

Az elkészült `upload` kulcs ujjlenyomatai, amelyeket most fel lehet venni:

```text
SHA-1:   29:10:E1:78:60:6E:EA:F2:51:BC:10:A8:0F:D9:3A:BF:FC:63:EB:82
SHA-256: 40:7B:C4:9B:3E:55:42:6C:4D:61:0A:C1:21:C0:DC:7E:33:43:EF:8F:B1:39:48:72:A3:07:A9:09:69:29:C2:F4
```

Újragenerálás bármikor:

```powershell
cd android
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
.\gradlew.bat signingReport
```

A már Cloud Console-ban lévő SHA-1 a Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs részben, az Android kliens megnyitásakor látható. A Firebase Console Project settings oldalán az apphoz felvett ujjlenyomatok szintén visszanézhetők. Ha ugyanaz a csomagnév + SHA-1 egy másik projekt Android OAuth kliensén szerepel, azt a régi projektben el kell távolítani vagy másik kiadási kulcsot kell használni; ugyanaz a páros nem tartozhat két projekthez.

Kiadáskor két tanúsítvány ujjlenyomatait kell kezelni:

- a saját upload keystore fenti SHA-1 és SHA-256 értékeit;
- az első Play-feltöltés után a Google Play Console → Protected with Play → Play Store distribution → Play app signing oldalon látható **App signing key certificate** SHA-1 és SHA-256 értékeit.

Az OAuth nyilvános megjelenését ugyanennek a Firebase-projektnek a Google Cloud Console felületén kell beállítani: Google Auth Platform → Branding. Az alkalmazás neve `Best Duo Fotó`, a támogatási e-mail `foto@bestduo.hu`, a kezdőlap `https://bestduo.hu/`, az adatkezelési URL `https://bestduo.hu/adatkezeles/`, az engedélyezett domain pedig `bestduo.hu`. Az Audience oldalon külső, éles használatra kell publikálni. Az app csak az alap profil- és e-mail-adatokat kéri, ezért érzékeny vagy korlátozott scope nincs használatban; a márkanév és logó nyilvános megjelenítéséhez brand verification szükséges lehet.

### 2. Apple-belépés

1. Az Apple Developerben regisztráld a `hu.bestduo.foto` App ID-t.
2. Engedélyezd rajta a Sign in with Apple és Push Notifications capabilityket.
3. Firebase Authentication → Sign-in method alatt engedélyezd az Apple providert, és add meg az Apple Team ID-t, Key ID-t és privát kulcsot.
4. Xcode-ban válassz fejlesztői Teamet a Runner targethez. A szükséges entitlements és capability-bejegyzések már a projektben vannak.

Az Apple-belépés csak iOS-en jelenik meg az alkalmazásban. A Google-belépéshez szükséges iOS URL scheme már az `Info.plist` része.

### 3. Firestore és opcionális push backend

1. A Firebase Console-ban hozz létre Cloud Firestore adatbázist Native módban.
2. A Cloud Messaging fülön az iOS apphoz tölts fel APNs `.p8` kulcsot, valamint add meg a Key ID-t és Team ID-t.
3. A Firestore szabályai és indexei a Spark csomagban is telepíthetők:

```powershell
npx firebase-tools login
npx firebase-tools use bestduomobilapp
npx firebase-tools deploy --only firestore:rules,firestore:indexes
```

Az automatikus push értesítést küldő Cloud Function opcionális, és csak Blaze csomagban telepíthető. Spark csomagban a publikált hír megjelenik az alkalmazásban, de a közzététel nem küld automatikus push értesítést. Ha később mégis szükség van rá:

```powershell
cd functions
npm install
cd ..
npx firebase-tools deploy --only functions
```

Az app a bejelentkezett felhasználót a `users`, az FCM tokeneket a `pushTokens`, a híreket az `announcements`, a szerkeszthető kapcsolati adatokat az `appConfig/contact` dokumentumban kezeli.

### Adminfelület és hírkezelés

A `bestduo.firebase@gmail.com` ellenőrzött Google-fiókkal belépő felhasználónak egy ötödik, **Kezelés** nevű menüpont jelenik meg. Innen:

- új, szöveges hír hozható létre, opcionális webes részletező linkkel;
- piszkozat menthető, majd külön megerősítéssel publikálható;
- a meglévő hírek szerkeszthetők, elrejthetők és törölhetők;
- szerkeszthető az üzlet címe, telefonszáma, e-mail-címe, nyitvatartása, Facebook-linkje és térképpontja.

A jogosultságot a kliens mellett a Firestore szabályai is ellenőrzik. Az admin e-mail-cím módosításakor a `lib/config/admin_access.dart` és a `firestore.rules` fájlt együtt kell frissíteni.

Ha az opcionális Cloud Function telepítve van, a publikálás egyszer küld push értesítést. Egy már kiküldött, majd elrejtett hír újbóli megjelenítése nem küld új push-t; új értesítéshez új hírt kell létrehozni.

Szükség esetén a Firebase Console-ból is létrehozható dokumentum az `announcements` kollekcióban:

A Firestore Console-ban hozz létre egy dokumentumot az `announcements` kollekcióban ezekkel a mezőkkel:

| Mező | Típus | Kötelező | Példa |
|---|---|---:|---|
| `title` | string | igen | `Őszi fotóakció` |
| `body` | string | igen | `Ezen a héten kedvezményes a 10×15-ös kép.` |
| `publishedAt` | timestamp | igen | aktuális dátum/idő |
| `isPublished` | boolean | igen | először `false` |
| `targetUrl` | string | nem | HTTPS részletező oldal |

Ha kész a tartalom, állítsd az `isPublished` mezőt `true` értékre. Az opcionális Function ekkor egyszer kiküldi a push-t, majd kitölti a `notificationState`, `notificationSentAt` és `deliverySummary` mezőket.

## Android release aláírás

Az `upload` kulcs létrejött az `android/upload-keystore.jks` fájlban, a hozzá tartozó helyi buildbeállítás és véletlenszerű jelszavak pedig az `android/key.properties` fájlban vannak. Mindkettő gitignore-olt. A két fájlról együtt kell biztonságos, titkosított külső mentést készíteni; a repó másolása vagy újraklónozása ezeket nem őrzi meg.

Ezután:

```powershell
flutter build appbundle --release
```

## Projektstruktúra

- `lib/screens/` – belépés, kezdőlap, fotórendelő, hírek, kapcsolat
- `lib/services/` – Firebase Auth és FCM/Firestore tokenkezelés
- `assets/` – eredeti Best Duo képi világ és a Manrope font
- `functions/` – hírből push-t küldő, hibás tokeneket takarító backend
- `firestore.rules` – felhasználói, token- és hír-adatok hozzáférési szabályai

## Publikálás előtt

- az App Store-képernyőképek az `assets/app_store_screenshots/` mappában találhatók 1284×2778 px felbontásban; újragenerálásuk: `powershell -ExecutionPolicy Bypass -File .\tooling\generate_app_store_screenshots.ps1`;
- a store-leírások és az adatbiztonsági nyilatkozatok feltöltés előtt még ellenőrizendők.

A Google-belépési gomb színes `G` emblémája a Google hivatalos Sign in with Google arculati eszközeiből származik: `assets/images/google_g_logo.png`.
