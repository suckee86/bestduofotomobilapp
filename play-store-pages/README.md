# Best Duo Fotó – Play Store weboldalak

Ez a mappa két, külső függőség és JavaScript nélkül működő statikus oldalt tartalmaz:

- `adatkezeles/index.html` → `https://bestduo.hu/adatkezeles/`
- `fioktorles/index.html` → `https://bestduo.hu/fioktorles/`
- `assets/styles.css` → a két oldal közös megjelenése

## Feltöltés

A három almappát (`adatkezeles`, `fioktorles`, `assets`) másold a `bestduo.hu` webes gyökérkönyvtárába úgy, hogy a fenti URL-ek közvetlenül, bejelentkezés nélkül és átirányítási hiba nélkül megnyíljanak. HTTPS használata szükséges.

A Google OAuth ellenőrzéséhez a `https://bestduo.hu/` főoldalon is legyen látható hivatkozás az adatkezelési tájékoztatóra.

## Kiadás előtti ellenőrzés

A projekt és a nyilvános weboldal csak a „Best Duo Fotó” márkanevet tartalmazza. Feltöltés előtt ellenőrizd, hogy ez megegyezik-e a Play Console-ban megjelenő fejlesztői névvel. Ha a szolgáltatás hivatalos adatkezelője magánszemély vagy más bejegyzett vállalkozás, az `adatkezeles/index.html` és `fioktorles/index.html` kapcsolati blokkjában a pontos hivatalos nevet is fel kell tüntetni.

Érdemes jogi szakemberrel ellenőriztetni különösen a fotórendelések és feltöltött képek tényleges megőrzési idejét. A jelenlegi szöveg célhoz kötött megőrzési feltételeket ír le, konkrét, nem igazolt határidőt nem állít.
