# homebrew-tap (papilip)

Tap Homebrew personnel regroupant mes recettes maison.

```bash
brew tap papilip/tap
```

---

## Recettes disponibles

### `tessdata-best-*` — modèles Tesseract OCR (variante *best*)

Le paquet officiel `tesseract-lang` installe la variante `tessdata_fast`, plus
rapide mais moins précise. Ces formules installent la variante
[`tessdata_best`](https://github.com/tesseract-ocr/tessdata_best) du projet
Tesseract OCR, optimisée pour la précision (au prix de la vitesse et de la
taille).

**Particularité du tap** : une formule par langue (ou script). Vous installez
seulement ce dont vous avez besoin, ou tout d'un coup avec
`tessdata-best-all`. Une formule outil (`tessdata-best`, sans suffixe)
fournit un wrapper `tesseract-best` qui pointe automatiquement sur les
modèles best — sans toucher à `tesseract` ni à `tessdata_fast`.

#### Installer

```bash
# Le wrapper (recommandé) + une ou plusieurs langues
brew install papilip/tap/tessdata-best papilip/tap/tessdata-best-{osd,fra,eng}

# Une langue seule (sans wrapper)
brew install papilip/tap/tessdata-best-fra

# Plusieurs en une commande
brew install papilip/tap/tessdata-best-{fra,eng,deu}

# Tout (wrapper + langues + scripts + osd + equ, ~1,7 Go)
brew install papilip/tap/tessdata-best-all
```

Les fichiers `.traineddata` sont installés dans
`/opt/homebrew/share/tessdata_best/`.

#### Lister

```bash
# Toutes les formules tessdata-best du tap
brew search /^tessdata-best/

# Filtrer par langue
brew search tessdata-best- | grep fra

# Détails d'une formule
brew info papilip/tap/tessdata-best-fra
```

Pour la liste complète des langues et scripts disponibles, voir le
[manifeste versionné](scripts/tessdata-best-manifest.tsv) ou la
[documentation Tesseract](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html).

#### Configurer Tesseract

**Option 1 — wrapper `tesseract-best` (recommandé).** Aucun export
nécessaire. La commande `tesseract` standard reste sur ses données par
défaut (`tessdata_fast` si vous avez `tesseract-lang`) ; `tesseract-best`
utilise toujours `tessdata_best`.

```bash
brew install papilip/tap/tessdata-best   # fournit `tesseract-best`
tesseract-best --list-langs
tesseract-best image.png out -l fra
tesseract-best image.png out -l fra+eng     # plusieurs langues
tesseract-best image.png out -l script/Latin
```

**Option 2 — variable d'environnement.** Si vous voulez que `tesseract`
lui-même utilise `tessdata_best` :

```bash
# Pour la session courante :
export TESSDATA_PREFIX="$(brew --prefix)/share/tessdata_best"

# Persistant (à ajouter à ~/.zshrc ou ~/.bashrc) :
echo 'source $(brew --prefix)/share/tessdata-best/env.sh' >> ~/.zshrc

# Ponctuel, sans toucher au shell :
TESSDATA_PREFIX="$(brew --prefix)/share/tessdata_best" tesseract image.png out -l fra
```

`tesseract-best` respecte `TESSDATA_PREFIX` si vous le définissez vous-même
(votre valeur a la priorité).

#### Mettre à jour

```bash
brew update
brew upgrade $(brew list | grep '^tessdata-best-')
```

Une vérification automatique tourne chaque lundi via GitHub Actions et ouvre
une issue lorsqu'un nouveau tag de `tessdata_best` est publié en amont.

#### Désinstaller

```bash
# Une langue
brew uninstall papilip/tap/tessdata-best-fra

# Tout (méta-formule, sans toucher aux langues qu'elle a tirées)
brew uninstall papilip/tap/tessdata-best-all

# Tout retirer (méta + langues)
brew uninstall $(brew list | grep '^tessdata-best-')
```

#### Comparaison `best` / `fast`

| Aspect            | `tesseract-lang` (officiel) | `tessdata-best-*` (ce tap) |
|-------------------|-----------------------------|----------------------------|
| Variante          | `tessdata_fast`             | `tessdata_best`            |
| Précision         | Standard                    | Maximale                   |
| Vitesse           | Plus rapide                 | Plus lente (~2× lent)      |
| Taille (toutes)   | ~600 Mo                     | ~1,7 Go                    |
| Langues sur mesure| Non                         | Oui (formule par langue)   |

Les deux variantes sont **incompatibles** sur le même `TESSDATA_PREFIX` :
choisissez l'une ou l'autre.

#### Dépannage

**`tesseract --list-langs` ne montre rien**

`TESSDATA_PREFIX` n'est probablement pas défini, ou pointe ailleurs :

```bash
echo $TESSDATA_PREFIX
ls "$(brew --prefix)/share/tessdata_best"
```

**`Error opening data file .../osd.traineddata`**

Le modèle OSD (détection d'orientation) est requis par Tesseract pour
plusieurs opérations. Installez-le :

```bash
brew install papilip/tap/tessdata-best-osd
```

**Conflit avec `tesseract-lang`**

Pas obligatoire si vous utilisez le wrapper `tesseract-best` (les deux
variantes coexistent : `tesseract` reste sur `tessdata_fast`,
`tesseract-best` utilise `tessdata_best`). Ne désinstallez `tesseract-lang`
que si vous avez exporté `TESSDATA_PREFIX` globalement et préférez n'avoir
qu'une seule variante :

```bash
brew uninstall tesseract-lang
```

---

## Mainteneur

### Régénération après une mise à jour amont

```bash
ruby scripts/update-tessdata-best.rb            # dernier tag
ruby scripts/update-tessdata-best.rb 4.2.0      # tag explicite
ruby scripts/update-tessdata-best.rb --check    # exit 3 si MAJ disponible
```

Le script télécharge les fichiers `.traineddata`, recalcule les SHA256,
réécrit `scripts/tessdata-best-manifest.tsv` et régénère toutes les formules
sous `Formula/`.

### Ajouter une autre recette

Posez votre formule dans `Formula/<nom>.rb` (en pur Ruby Homebrew, pas de
génération nécessaire). Validez avec :

```bash
brew audit --strict --new --tap=papilip/tap <nom>
brew install --build-from-source papilip/tap/<nom>
brew test papilip/tap/<nom>
```

---

## Documentation Homebrew

`brew help`, `man brew`, ou
[docs.brew.sh](https://docs.brew.sh).
