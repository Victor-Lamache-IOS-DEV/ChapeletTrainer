# ChapeletTrainer ♠️♥️♦️♣️

Application native iOS conçue en **Swift 5.9+** et **SwiftUI** pour apprendre par cœur le légendaire chapelet **Mnemonica de Juan Tamariz**.

Simple, ultra-rapide, 100% hors ligne, sans compte ni publicité.

---

## 📱 Fonctionnalités

1. **Chapelet (Vue Grille OLED)** :
   - Fond noir pur OLED (`#000000`).
   - Grille de 4 colonnes affichant les 52 cartes du chapelet avec leurs illustrations vectorielles.
   - Badge circulaire sombre (`#2C2C2E`) avec numéro blanc à cheval sur le coin supérieur droit.
   - Fiche détaillée au toucher : carte en grand, position, indice modifiable avec sauvegarde automatique, statistiques et 10 dernières réponses.
   - **Mode Révision** : 3 états (*Tout afficher*, *Masquer les numéros*, *Masquer les cartes*). Toucher une carte révèle l'élément caché.

2. **Indices (Phrases Mnémotechniques)** :
   - Liste des 52 cartes avec miniatures, numéros et champs textes à sauvegarde continue.
   - Filtre « Sans indice uniquement » pour cibler les cartes restantes.
   - Export et Import de l'ensemble de vos indices en format JSON via la feuille de partage native.

3. **Entraînement / Tests** :
   - **Sélection flexible** : Grille des 52 cartes (sélection conservée) avec raccourcis instantanés (*Tout*, *Aucune*, *1-13*, *14-26*, *27-39*, *40-52*, *Cartes faibles*).
   - **3 modes de quiz** :
     - *Carte → Position* : Une carte s'affiche, saisie de la position sur un pavé numérique personnalisé.
     - *Position → Carte* : Un numéro s'affiche, sélection dans une grille de 52 miniatures classées par couleur et par valeur (pas dans l'ordre du chapelet).
     - *Mixte* : Alternance fluide des deux modes.
   - **Tirage pondéré** : Les cartes ayant un fort taux d'erreur récent reviennent plus souvent.
   - **Feedback immédiat** : Retour haptique et visuel (vert/rouge) ; en cas d'erreur, affichage de la bonne carte et de l'indice mnémotechnique.
   - **Résultats complets** : Taux de réussite, durée indicative, liste détaillée des erreurs et bouton « Refaire avec les erreurs ».

4. **Statistiques & Progression** :
   - Vue d'ensemble : Taux global, nombre de sessions, nombre de cartes maîtrisées.
   - **Heatmap des 52 cartes** : Code couleur dynamique (Gris = non testée, Rouge < 50%, Orange 50-79%, Vert ≥ 80%, indicateur < 3 tests).
   - **Top 10 des cartes difficiles** : Classement par taux d'erreur récent puis total d'erreurs.
   - **Graphique Swift Charts** : Courbe de progression par session.
   - Réinitialisation sécurisée des statistiques.

> **Règle fondamentale** : Le temps de réponse n'influence **jamais** la heatmap, le classement des difficultés ou le tirage pondéré, afin d'éliminer tout biais (pauses, interruptions).

---

## 🛠️ Stack Technique

- **Langage** : Swift 5.9+
- **UI** : 100% SwiftUI
- **Cible** : iOS 17.0+
- **Persistance** : SwiftData en local
- **Graphiques** : Swift Charts
- **Génération de projet** : XcodeGen (`project.yml`)
- **Dépendances tierces** : Aucune (Frameworks Apple natifs uniquement)

---

## 🎨 Graphismes des Cartes

Les visuels proviennent du projet [Vector-Playing-Cards](https://github.com/notpeter/Vector-Playing-Cards) par notpeter, basé sur le travail dans le domaine public de Byron Knoll.
- 52 SVG intégrés dans `Assets.xcassets` avec *Preserve Vector Data* et *Single Scale*.
- Plan B natif vectoriel SwiftUI intégré en cas d'absence d'image.
- Dos de carte conçu sur-mesure en SwiftUI.

---

## 🚀 Compilation & Déploiement

Le projet utilise **XcodeGen** pour générer le fichier `.xcodeproj` à la volée.

```bash
# Générer le projet Xcode
xcodegen generate

# Lancer les tests unitaires
xcodebuild test -scheme ChapeletTrainer -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

Le workflow GitHub Actions `.github/workflows/build.yml` compile automatiquement l'IPA signé avec le certificat de l'organisation lors de chaque push.
