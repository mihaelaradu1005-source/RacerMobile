# RacerMobile — Progress Tracker

Joc de curse pentru mobil, construit în Godot 4.3+ cu GDScript.
Android-first, iOS ulterior. Doar resurse gratuite/open-source.

**Faza curentă:** 🚧 Faza 2 în lucru — vehicul cu raycast (mașină pe 4 roți)
**Ultima actualizare:** 2026-07-03

---

## Faza 0 — Setup (Săptămâna 1) ✅

- [x] Instalare Godot 4.6.2 stable (Standard, win64)
- [x] Configurare Android export template în Godot
- [x] Instalare Android SDK + JDK 25 + adb
- [x] Creare repo GitHub `mihaelaradu1005-source/RacerMobile`
- [x] `.gitignore` pentru Godot 4
- [x] Structură foldere: `scenes/`, `scripts/`, `assets/`, `resources/`, `tests/`
- [x] `README.md` cu instrucțiuni de rulare
- [x] `ASSETS_LICENSES.md` pregătit
- [x] Scenă inițială cu Label „RacerMobile v0.0.1" pe fundal negru
- [x] Export APK debug (`com.maid.racermobile`, 27.6 MB)
- [x] Instalare APK pe telefon și verificare că pornește
- [x] **Deliverable:** APK care pornește pe telefon și afișează ecran negru cu textul „RacerMobile v0.0.1" ✓

**Decizii / abateri de la plan:**
- Folosim Godot 4.6.2 (mai nou decât 4.3) — compatibil înapoi.
- JDK 25 LTS în loc de 17 — Adoptium servește 25 ca LTS curent. A funcționat fără probleme la build.
- `display/window/handheld/orientation = 1` (landscape) setat din Faza 0 — pregătit pentru jocul de curse.
- `Jolt Physics` ca engine 3D — default Godot 4.6, foarte bun pentru fizică auto.

---

## Faza 1 — Movement de bază 3D (Săptămâna 2-3)

- [x] Scenă 3D cu o platformă plată (PlaneMesh + StaticBody3D)
- [x] Cub controlabil (CharacterBody3D + MeshInstance3D)
- [x] Joystick virtual stânga (input touch) — desenat din cod, jumătatea stângă a ecranului
- [ ] Butoane dreapta (input touch) — amânat: cubul n-are încă acțiuni; vin cu mașina în Faza 2
- [x] Cameră third-person cu smoothing (Camera3D + script de follow)
- [ ] Test pe telefon ← urmează: build APK + verificare pe telefonul tău
- [ ] **Deliverable:** cub controlabil de pe telefon, fără fizică de mașină încă

---

## Faza 2 — Vehicul cu raycast (Săptămâna 4-6)

- [x] Înlocuire cub cu `VehicleBody3D` — confirmat că merge cu Jolt (test automat)
- [x] 4 roți pe raycast (`VehicleWheel3D`) — 2 față (direcție), 2 spate (tracțiune)
- [x] Suspensii cu spring + damper, parametri `@export`
- [x] Accelerație + frână + viraj (fără transmisie încă)
- [x] Pistă de test cu praguri (denivelări) — `world.tscn` are 3 praguri
- [ ] Test pe telefon ← urmează: build APK + verificare pe telefonul tău
- [ ] **Deliverable:** mașină care merge, virează, se balansează credibil pe denivelări

**Note Faza 2:**
- Verificat automat (headless): mașina stă pe 4 roți, accelerează stabil, virează corect (dreapta = dreapta). Fără NaN/instabilități.
- Camera e acum „chase cam" — stă în spatele mașinii și se rotește cu ea la viraje.
- `tests/vehicle_test.tscn` = test automat reutilizabil pentru fizica mașinii.
- `tests/input_path_test.tscn` = test pentru traseul joystick → mașină (a prins un bug).
- **Bug reparat:** mașina nu se mișca pe telefon — căuta joystick-ul o singură dată la
  `_ready()`, înainte ca joystick-ul să se înregistreze (node ready-order). Acum îl caută
  leneș + joystick-ul se anunță în `_enter_tree()`. Nu s-a văzut pe PC (acolo merge tastatura).
- De reglat pe telefon după feel: `max_engine_force`, `max_steer_angle`, `steer_speed`, `wheel_friction_slip`, parametrii de suspensie.

---

## Faza 3 — Fizică auto avansată (Săptămâna 7-10)

- [ ] Model anvelope: slip ratio + slip angle (Pacejka simplificată)
- [ ] Transmisie cu trepte (automată)
- [ ] Coeficient de fricțiune diferit asfalt vs. iarbă
- [ ] Transfer de greutate la accelerație/frânare
- [ ] Test pe telefon
- [ ] **Deliverable:** derapaj credibil, limite de aderență, comportament diferit pe suprafețe

---

## Faza 4 — Pistă completă + AI (Săptămâna 11-14)

- [ ] Pistă închisă oval simplu
- [ ] Pistă cu 8-10 viraje
- [ ] Sistem checkpoint-uri (Area3D)
- [ ] Cronometrare lap + best time
- [ ] AI care urmărește un spline (`Path3D` + `PathFollow3D`)
- [ ] AI frânează în viraje
- [ ] HUD: viteză, treaptă, timp, poziție
- [ ] **Deliverable:** mod „time trial" + mod „race vs 1 AI", complet jucabile

---

## Faza 5 — Conținut și feel (Săptămâna 15-20)

- [ ] 3 mașini cu stat-uri diferite (acceleration, top speed, handling, mass)
- [ ] 3 piste cu personalități diferite (tehnică, viteză, mixt)
- [ ] Sunet motor procedural (sample + pitch shift după RPM)
- [ ] Particule: fum derapaj, praf iarbă, scântei coliziune
- [ ] Meniu principal
- [ ] Selectare mașină
- [ ] Selectare pistă
- [ ] Ecran settings
- [ ] Ecran results
- [ ] Salvare progres (record-uri, mașini deblocate) — `user://save.cfg`
- [ ] **Deliverable:** joc complet jucabil cu progresie minimală

---

## Faza 6 — Polish și soft launch (Săptămâna 21-24)

- [ ] Profiling: target 30 FPS pe telefon de 200€
- [ ] Profiling: target 60 FPS pe flagship
- [ ] Setări grafice (Low/Medium/High) cu auto-detect
- [ ] Tutorial scurt în primele 30 secunde
- [ ] Localizare RO + EN
- [ ] Build semnat pentru Google Play Internal Testing
- [ ] 20-50 testeri invitați
- [ ] **Deliverable:** APK în Internal Testing cu testeri reali

---

## Note de sesiune

<!-- La finalul fiecărei sesiuni adaugă aici scurt: ce am terminat, ce urmează. -->

### 2026-04-28 — Sesiune 1 ✅ Faza 0 încheiată
- Creat docs (`PROGRESS.md`, `.gitignore`, `README.md`, `ASSETS_LICENSES.md`)
- Repo Git inițializat și pushed pe `mihaelaradu1005-source/RacerMobile`
- Structură foldere creată cu `.gitkeep`-uri
- Scena `scenes/main.tscn` cu Label centrat
- `project.godot` configurat: main_scene + display landscape 1280×720
- JDK 25 + Android SDK + Android Studio + `debug.keystore` instalate
- Editor Settings configurat (Android SDK Path, Java SDK Path, Debug Keystore + Pass + User)
- Export preset Android cu Unique Name `com.maid.racermobile`
- ETC2 ASTC texture compression activat
- APK 27.6 MB construit, instalat cu `adb install` pe telefon `37241FDJG007FB`
- App lansată: ecran negru + „RacerMobile v0.0.1" în landscape ✓
- **Următoarea sesiune:** Faza 1 — primul cub controlabil în 3D
