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
`tessdata-best-all`.

#### Installer

```bash
# Une langue
brew install papilip/tap/tessdata-best-fra

# Plusieurs en une commande
brew install papilip/tap/tessdata-best-{fra,eng,deu}

# Tout (langues + scripts + osd + equ, ~1,7 Go)
brew install papilip/tap/tessdata-best-all
```

Les fichiers sont installés dans `/opt/homebrew/share/tessdata_best/`.

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

Une seule variable d'environnement à définir :

```bash
export TESSDATA_PREFIX="$(brew --prefix)/share/tessdata_best"
```

Ajoutez-la à votre `~/.zshrc` (ou `~/.bashrc`). Puis :

```bash
tesseract --list-langs
tesseract image.png out -l fra
tesseract image.png out -l fra+eng     # plusieurs langues
tesseract image.png out -l script/Latin
```

Pour un usage ponctuel sans modifier le shell :

```bash
TESSDATA_PREFIX="$(brew --prefix)/share/tessdata_best" tesseract image.png out -l fra
```

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

Désinstallez l'un des deux pour éviter les ambiguïtés :

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
