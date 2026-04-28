# RacerMobile

Joc de curse 3D pentru mobil cu fizică auto care „se simte" realistă, fără să fie fotorealistă. Inspirat de feel-ul Forza / Gran Turismo, dar adaptat pe constrângerile unui telefon mediu (sub 4GB RAM, GPU mid-range).

**Status:** în dezvoltare — Faza 0 (Setup).
**Platformă target:** Android API 24+ (Android 7+) → iOS 13+ ulterior.

---

## Stack tehnic

- **Engine:** Godot 4.3+ (NU Godot 3.x)
- **Limbaj:** GDScript
- **Renderer:** Forward+ în development, Mobile/Compatibility la export
- **Versionare:** Git + GitHub
- **Asset-uri:** doar gratuite, licență permisivă (Kenney, Quaternius, Poly Pizza, OpenGameArt, freesound)

---

## Structura proiectului

```
RacerMobile/
├── scenes/         # Fișiere .tscn (scene Godot)
├── scripts/        # Fișiere .gd (GDScript)
├── assets/         # Modele 3D, texturi, sunete, fonturi
├── resources/      # .tres (Resources reutilizabile: PhysicsMaterial, CarStats etc.)
├── tests/          # Scene/script-uri de test izolate
├── PROGRESS.md     # Tracker faze + checkbox-uri
├── ASSETS_LICENSES.md  # Tracking licențe asset-uri
└── README.md
```

---

## Setup local

### 1. Instalare Godot
1. Descarcă **Godot 4.3+ Standard** (NU .NET) de pe https://godotengine.org/download
2. Rulează executabilul (nu necesită instalare).

### 2. Clonare repo
```bash
git clone https://github.com/<username>/RacerMobile.git
cd RacerMobile
```

### 3. Deschidere în Godot
- Lansează Godot → `Import` → selectează `project.godot` din folderul clonat.
- Apasă `Import & Edit`.

### 4. Rulare în editor
- F5 pentru a rula scena principală.

### 5. Export Android (vezi instrucțiuni detaliate în PROGRESS / sesiunea curentă)
- Necesită: Android SDK, JDK 17, debug keystore generat.
- Project → Export → Android → Export Project (APK debug).

---

## Convenții de cod

- Cod, comentarii și nume de fișiere/funcții: **engleză**.
- Constante magice → variabile cu nume clar (ex: `const MAX_STEERING_ANGLE = 35.0`).
- `@export` pentru orice parametru reglabil din Inspector.
- Fizică în `_physics_process`, nu în `_process`.
- Signals preferați la apeluri directe între noduri.
- Funcții scurte (sub 30 linii ideal).
- Un script = un fișier = o responsabilitate.

## Convenții de commit

- Mesaje în engleză.
- Commit-uri mici și dese.
- Format: `<type>: <short description>`
  - `feat:` feature nou
  - `fix:` bug fix
  - `chore:` setup, config, build
  - `docs:` documentație
  - `refactor:` cod curățat fără schimbări funcționale

---

## Licență

TBD (probabil MIT pentru cod). Asset-urile au licențele lor proprii — vezi `ASSETS_LICENSES.md`.
