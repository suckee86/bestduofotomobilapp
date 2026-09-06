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

Újragenerálás bármikor:

```powershell
cd android
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
.\gradlew.bat signingReport
```

A már Cloud Console-ban lévő SHA-1 a Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs részben, az Android kliens megnyitásakor látható. A Firebase Console Project settings oldalán az apphoz felvett ujjlenyomatok szintén visszanézhetők. Ha ugyanaz a csomagnév + SHA-1 egy másik projekt Android OAuth kliensén szerepel, azt a régi projektben el kell távolítani vagy másik kiadási kulcsot kell használni; ugyanaz a páros nem tartozhat két projekthez.

Kiadáskor még két ujjlenyomatot kell felvenni:

- a saját upload/release keystore SHA-1 és SHA-256 értékeit;
- publikálás után a Google Play Console → Release → Setup → App signing oldalon látható App signing key SHA-1 és SHA-256 értékeit.

### 2. Apple-belépés

1. Az Apple Developerben regisztráld a `hu.bestduo.foto` App ID-t.
2. Engedélyezd rajta a Sign in with Apple és Push Notifications capabilityket.
3. Firebase Authentication → Sign-in method alatt engedélyezd az Apple providert, és add meg az Apple Team ID-t, Key ID-t és privát kulcsot.
4. Xcode-ban válassz fejlesztői Teamet a Runner targethez. A szükséges entitlements és capability-bejegyzések már a projektben vannak.

Az Apple-belépés csak iOS-en jelenik meg az alkalmazásban. A Google-belépéshez szükséges iOS URL scheme már az `Info.plist` része.

### 3. Firestore és push backend

1. A Firebase Console-ban hozz létre Cloud Firestore adatbázist Native módban.
2. A Cloud Messaging fülön az iOS apphoz tölts fel APNs `.p8` kulcsot, valamint add meg a Key ID-t és Team ID-t.
3. A Cloud Functions telepítéséhez a projektet Blaze csomagra kell állítani.
4. Telepítsd és deployold a backendet:

```powershell
cd functions
npm install
cd ..
npx firebase-tools login
npx firebase-tools use bestduomobilapp
npx firebase-tools deploy --only firestore:rules,firestore:indexes,storage,functions
```

Az app a bejelentkezett felhasználót a `users`, az FCM tokeneket a `pushTokens`, a híreket az `announcements`, a szerkeszthető kapcsolati adatokat az `appConfig/contact` dokumentumban kezeli. A hírekhez feltöltött képek a Firebase Storage `announcements` mappájába kerülnek.

### Adminfelület és push/hír küldése

A `bestduo.firebase@gmail.com` ellenőrzött Google-fiókkal belépő felhasználónak egy ötödik, **Kezelés** nevű menüpont jelenik meg. Innen:

- új hír és borítókép tölthető fel;
- piszkozat menthető, majd külön megerősítéssel publikálható;
- a meglévő hírek szerkeszthetők, elrejthetők és törölhetők;
- szerkeszthető az üzlet címe, telefonszáma, e-mail-címe, nyitvatartása, Facebook-linkje és térképpontja.

A jogosultságot a kliens mellett a Firestore és Storage szabályai is ellenőrzik. Az admin e-mail-cím módosításakor a `lib/config/admin_access.dart`, a `firestore.rules` és a `storage.rules` fájlt együtt kell frissíteni.

A publikálás egyszer küld push értesítést. Egy már kiküldött, majd elrejtett hír újbóli megjelenítése nem küld új push-t; új értesítéshez új hírt kell létrehozni.

Szükség esetén a Firebase Console-ból is létrehozható dokumentum az `announcements` kollekcióban:

A Firestore Console-ban hozz létre egy dokumentumot az `announcements` kollekcióban ezekkel a mezőkkel:

| Mező | Típus | Kötelező | Példa |
|---|---|---:|---|
| `title` | string | igen | `Őszi fotóakció` |
| `body` | string | igen | `Ezen a héten kedvezményes a 10×15-ös kép.` |
| `publishedAt` | timestamp | igen | aktuális dátum/idő |
| `isPublished` | boolean | igen | először `false` |
| `imageUrl` | string | nem | HTTPS képcím |
| `targetUrl` | string | nem | HTTPS részletező oldal |

Ha kész a tartalom, állítsd az `isPublished` mezőt `true` értékre. A Function ekkor egyszer kiküldi a push-t, majd kitölti a `notificationState`, `notificationSentAt` és `deliverySummary` mezőket.

## Android release aláírás

A release build szándékosan nincs debug kulccsal aláírva. Hozz létre külön upload keystore-t, másold az `android/key.properties.example` fájlt `android/key.properties` néven, majd töltsd ki. A valódi keystore és `key.properties` gitignore-olt; ezeket biztonságos, mentett helyen kell tartani.

Ezután:

```powershell
flutter build appbundle --release
```

## Projektstruktúra

- `lib/screens/` – belépés, kezdőlap, fotórendelő, hírek, kapcsolat
- `lib/services/` – Firebase Auth és FCM/Firestore tokenkezelés
- `assets/` – eredeti Best Duo képi világ és a Manrope font
- `functions/` – hírből push-t küldő, hibás tokeneket takarító backend
- `firestore.rules` – felhasználói és tokenadatok hozzáférési szabályai

## Publikálás előtt

- végleges adatkezelési tájékoztató és publikus URL szükséges a belépési képernyőhöz és az áruházi adatlapokhoz;
- létre kell hozni az Android upload kulcsot és az iOS provisioning profile-okat;
- valós eszközön végig kell próbálni a Google/Apple belépést, a fotófeltöltést és a push-t;
- az App Store/Play Store képernyőképek, leírások és adatbiztonsági nyilatkozatok még elkészítendők.
