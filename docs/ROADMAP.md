# Roadmap Cleanpasty

Stan na 18.11.2026. Co zrobione, co teraz i co dalej. Decyzje: [DECYZJE.md](DECYZJE.md). Historia zmian: [CHANGELOG.md](../CHANGELOG.md).

## Zrobione

| Kiedy | Co |
|---|---|
| 29.09-01.10.2026 | **1.0.0 i 1.0.1:** pasek menu, Paste Clean i Repair Clipboard, CLI, Sparkle z kluczem EdDSA (ten sam do dziś). |
| 15.10.2026 | **1.1.0:** nazwa Cleanpasta, numerowane punkty jako akapity (D12). |
| 21.10-02.11.2026 | Audyt konwertera i CLI, podgląd Windows (D14). |
| 07-18.11.2026 | **1.2.0 w kodzie (PR #5):** sama nazwa Cleanpasta z podpisem Eryk Sadowski (D16), identyfikator `com.eryksadowski.cleanpasta` (D9), certyfikat "Eryk Sadowski" (D8), bez Raycasta (D17), porządek w repo. |
| 18.11.2026 | **Wyrównanie do Mowy:** aktualizacje z Cloudflare (Worker `cleanpasta`, R2 `cleanpasta-releases`, D7), CLI w `~/.local/bin` (D11), klucz Sparkle w `~/.config/eryksadowski/signing` pod nazwą jak w Mowie i `make-update-key.sh --check` (D18), dokładna nazwa certyfikatu w `build-app.sh`, dokumenty `DECYZJE`, `ROADMAP`, `dystrybucja`, repo bez starych nazw i kodu migracji (D10). |

## Teraz

**Wydanie 1.2.0** ([dystrybucja](dystrybucja.md#wydanie-krok-po-kroku)): PR `development` -> `main`, data w CHANGELOG, `scripts/release.sh` (uruchamia Eryk), instalacja na Macu Eryka (Dostępność, Open at login), potem sprzątanie starych wpisów w systemie i starych kopii kluczy (lista w karcie aplikacji w `eryksadowski-docs`).

## Dalej

- Strona `cleanpasta.eryksadowski.com` w Workerze `cleanpasta` i appcast pod tym adresem (D7), po przeniesieniu strefy `eryksadowski.com`.
- Wydanie z GitHub Actions po zmianie wersji na `main` (klucz EdDSA i certyfikat jako sekrety) - do decyzji, bo certyfikat trzyma Eryk.
- Jak w Mowie, po teście na osobnej wersji: hardened runtime w buildzie wydania (JavaScriptCore bez JIT albo z `allow-jit`), `SUVerifyUpdateBeforeExtraction`.
- Windows: akceptacja architektury, testy ręczne, klucz aktualizacji, decyzja o podpisie Authenticode ([windows.md](windows.md)).
- Później: polska lokalizacja interfejsu.

## Ryzyka

| Ryzyko | Co robimy |
|---|---|
| Brak notaryzacji: DMG z przeglądarki trzeba raz otworzyć przez "Otwórz mimo to" | instalacja komendą curl (bez ostrzeżeń), instrukcja dla DMG |
| Utrata klucza EdDSA albo certyfikatu: zainstalowane apki nie przyjmą aktualizacji | kopie w 1Password, `make-update-key.sh --check` przed każdym wydaniem |
| Wersje do 1.1.0 czytają appcast z GitHuba przez przekierowanie po dawnej nazwie repo | nie zakładać repo o dawnej nazwie na koncie `iameryksadowski` (karta aplikacji w `eryksadowski-docs`); każde wydanie publikuje appcast także na GitHubie |
| Konflikt skrótu z inną apką | ustawienia pokazują błąd, skrót można zmienić albo usunąć |
