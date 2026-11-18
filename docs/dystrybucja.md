# Budowanie i dystrybucja

Jak Cleanpasta jest budowana, podpisywana, aktualizowana i wydawana. Ten sam układ co `docs/dystrybucja.md` w Mowie. Decyzje: [DECYZJE.md](DECYZJE.md).

## Build lokalny

- `scripts/test.sh` - znaki z klawiatury, testy konwertera, build CLI i zgodność JavaScriptCore z konwerterem TypeScript (najpierw `pnpm install` w `converter/`).
- `CODE_SIGN_IDENTITY=- DIST=<folder> scripts/build-app.sh` - paczka testowa podpisana ad-hoc, bez pytania pęku kluczy. Tak budują agenci.
- `scripts/build-app.sh` - `dist/Cleanpasta.app`, zip i DMG (uniwersalne: Apple silicon i Intel), podpis certyfikatem "Eryk Sadowski", gdy jest w pęku kluczy.

Ciężkie buildy na Macu Eryka idą przez wspólną blokadę: `lockf -k -t 1800 /tmp/heavy-build.lock <komenda>`.

## Podpis

| Podpis | Gdzie | Uprawnienia po aktualizacji | Do czego |
|---|---|---|---|
| ad-hoc (`CODE_SIGN_IDENTITY=-`) | brak | znikają | testy agentów i CI |
| samopodpis "Eryk Sadowski" | pęk kluczy login | zostają | wydania |

Certyfikat "Eryk Sadowski" jest jeden dla wszystkich aplikacji Eryka (Mowa D4, D13; tu D8). Tworzy go i importuje skrypt Mowy `apps/macos/scripts/make-signing-identity.sh` (`--check`, `--import plik.p12`); kopia jest w 1Password ("Eryk Sadowski - code signing") i w `~/.config/eryksadowski/signing/eryk-sadowski-code-signing.*`. Cleanpasta niczego w pęku kluczy nie tworzy. `build-app.sh` szuka tożsamości o dokładnie tej nazwie (skrót SHA-1, jak `signing.sh` w Mowie), a `release.sh` (`REQUIRE_SIGNING=1`) odmawia podpisu ad-hoc. `security find-identity -v` nie pokazuje samopodpisanego certyfikatu (`CSSMERR_TP_NOT_TRUSTED`); to normalne, `codesign` nim podpisuje.

Agenci nie podpisują certyfikatem (standard aplikacji, `eryksadowski-docs/aplikacje/standardy.md`): wydanie uruchamia Eryk jedną komendą.

## Klucz aktualizacji (Sparkle EdDSA)

- Publiczny: `Resources/sparkle-public-key.txt`, wbudowany w każdą wersję od 1.0.0 jako `SUPublicEDKey`.
- Prywatny: `~/.config/eryksadowski/signing/cleanpasta-sparkle-private-key.txt` (0600), nazwa jak `mowa-sparkle-private-key.txt` Mowy. Kopia w 1Password: "Cleanpasta - klucz aktualizacji Sparkle" (sejf Work, załącznik `txt`).
- `scripts/make-update-key.sh --check` mówi, czy klucze do siebie pasują; `release.sh` sprawdza to przed buildem i po podpisie weryfikuje zip niezależnie od kodu Sparkle (`scripts/ed25519-tool.swift`, CryptoKit, to samo narzędzie co w Mowie).
- Nowego klucza nie robimy nigdy: zainstalowane apki przyjmują tylko aktualizacje podpisane kluczem, który niosą. `make-update-key.sh` bez `--check` odmawia, gdy klucz publiczny już jest.

## Aktualizacje

Sparkle 2.10.0 (SwiftPM, wersja przypięta w `Package.resolved`), sprawdzanie raz na dobę, instalacja po zgodzie użytkownika, changelog w oknie aktualizacji. Apka wysyła tylko pobranie `appcast.xml` i paczki; profil systemu (`SUEnableSystemProfiling`) jest wyłączony.

### Hosting na Cloudflare (jak Mowa)

- Konto Cloudflare "Eryk Sadowski" (`account_id` przypięty w `services/updates/wrangler.toml`).
- Worker `cleanpasta` (`services/updates/src/index.ts`) podaje tylko `/updates/appcast.xml` i `/updates/<wersja>/Cleanpasta-<wersja>.zip` z bucketu R2 `cleanpasta-releases`; reszta to 404, a `/` przekierowuje do repo, dopóki nie ma strony. Bez sekretów, bez logów.
- `SUFeedURL` = `https://cleanpasta.eryksadowski.workers.dev/updates/appcast.xml` (`Resources/Info.plist`). Adres jest zapisany w każdej zainstalowanej kopii, więc `workers.dev` zostaje włączone na zawsze.
- Wdrożenie Workera po zmianie: `cd services/updates && pnpm dlx wrangler@4.151.0 deploy`.
- Później, po przeniesieniu strefy `eryksadowski.com` na to konto (jak Mowa D21): odkomentować `routes` w `wrangler.toml`, wdrożyć, zmienić `SUFeedURL` na `https://cleanpasta.eryksadowski.com/updates/appcast.xml` i wydać jedną aktualizację.
- Każda wersja idzie też do GitHub Release: DMG i `install.sh` (pierwsza instalacja), a `appcast.xml` dla wersji do 1.1.0, które czytają appcast z najnowszego wydania na GitHubie. Wpis w tym appcaście wskazuje paczkę na Cloudflare.

### Aktualizacja z 1.1.0 do 1.2.0

1.2.0 zmienia naraz identyfikator i certyfikat. Sparkle 2.10 (`SUUpdateValidator`) przyjmuje paczkę, gdy podpis EdDSA zgadza się z kluczem starej apki albo podpis kodu zgadza się ze starym; klucz EdDSA jest ten sam, a nowy podpis kodu musi być tylko poprawny. Identyfikatora nowej paczki Sparkle nie porównuje. Zmiana klucza razem z certyfikatem odcięłaby aktualizacje, dlatego klucz zostaje na zawsze.

Po aktualizacji apka startuje jak nowa instalacja (D10): pyta o Dostępność, ma domyślne skróty i opcje, a Open at login trzeba włączyć w ustawieniach. CLI przenosi się do `~/.local/bin` (D11).

## Wydanie krok po kroku

1. PR `development` -> `main`, merge.
2. Na `main`: data wersji w `CHANGELOG.md` (`## [X.Y.Z] - RRRR-MM-DD`), commit.
3. Eryk uruchamia `scripts/release.sh` na `main`:
   - sprawdza klucz aktualizacji (`make-update-key.sh --check`),
   - buduje z podpisem "Eryk Sadowski" (macOS może raz zapytać o dostęp `codesign` do klucza certyfikatu: "Zawsze pozwalaj"),
   - podpisuje zip EdDSA i weryfikuje podpis,
   - pisze `appcast.xml` z notatkami z CHANGELOG,
   - wgrywa zip, potem appcast do R2 (`wrangler r2 object put`, logowanie wranglera Eryka) i sprawdza, że Worker podaje nową wersję,
   - publikuje GitHub Release `vX.Y.Z` (zip, DMG, `Cleanpasta.zip`, `appcast.xml`, `install.sh`).
4. Wersja jest w jednym miejscu dla apki (`CHANGELOG.md`, czyta ją `build-app.sh`), a w CLI, testach, skillu i plikach Windows (`Cargo.toml`, `Cargo.lock`, `tauri.conf.json`, `windows/app/ui/index.html`) ustawiana ręcznie na tę samą wartość.
5. Po wydaniu: `main` scalony z powrotem do `development`, jeśli coś zmieniło się na `main`.

## Instalacja na tym Macu

```bash
curl -fsSL https://github.com/iameryksadowski/cleanpasta-app/releases/latest/download/install.sh | sh
```

`install.sh` zamyka działającą Cleanpastę (także starszą wersję), podmienia `/Applications/Cleanpasta.app` z kopią zapasową na czas instalacji i otwiera nową wersję.
