# Notes Audio

Prototype initial d’une application iOS native, personnelle et locale. **Le parcours audio local est une première implémentation non compilée et non validée sur appareil.** La transcription, les résumés et les exports restent à développer.

## Projet

Sur Mac avec Xcode et XcodeGen (configuration initialement prévue pour 2.42.0 ; version non vérifiée dans cet environnement) : `xcodegen generate`, puis ouvrir `NotesAudio.xcodeproj`. La configuration de référence est `project.yml` ; le projet généré ne doit pas être maintenu séparément. Compiler pour simulateur avec `xcodebuild -project NotesAudio.xcodeproj -scheme NotesAudio -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build`. Exécuter les tests portables avec `swift test`.

iOS 17 est provisoirement retenu pour l’interface initiale et devra être réévalué lors de l’intégration des API système. L’installation sur appareil nécessite une équipe Apple et une signature configurées séparément.

## État de validation

Le développement initial a été effectué sous Linux sans Swift, Xcode, SDK Apple ou simulateur. Ni la compilation ni les tests n’ont été exécutés. Aucun accès à un microphone, fournisseur IA ou appareil physique n’a été validé. Voir [architecture et travail restant](docs/architecture.md).

## Avancement des fonctionnalités

Ce tableau décrit l’état du code et les validations réellement effectuées. Il doit être mis à jour à chaque évolution concernée, dans le même changement que le code ou les tests. « Partiel » ne signifie pas que la fonctionnalité est prête à l’emploi.

| Fonctionnalité | État | Limites et validation |
|---|---|---|
| Projet SwiftUI et XcodeGen | Ébauche | Génération et compilation non vérifiées. |
| Domaine et modèles portables | Partiel | Enregistrement, marqueurs et transcriptions esquissés ; modèles et migrations incomplets. |
| Tests portables | Écrits, non exécutés | Deux tests de modèles ; Swift indisponible dans l’environnement initial. |
| Capture audio locale | Partiel | Première implémentation AAC/M4A, non compilée ni vérifiée sur iPhone. |
| Pause, reprise, arrêt | Partiel | Commandes présentes ; transitions et erreurs à valider. |
| Durée, niveau et marqueurs | Partiel | Affichage et ajout de marqueurs présents ; précision et récupération à vérifier. |
| Interruptions et routes audio | Partiel | Certaines notifications sont traitées ; appels et Bluetooth restent à tester. |
| Capture en arrière-plan et écran verrouillé | À valider | Mode audio déclaré, comportement réel non testé. |
| Manque d’espace et finalisation | À faire | Détection et traitement des erreurs insuffisants. |
| Récupération après arrêt brutal | Partiel | Réintégration des fichiers orphelins lisibles ; intégrité et marqueurs non garantis. |
| Bibliothèque et persistance | Partiel | Liste et index JSON ; migrations et réparation à compléter. |
| Lecture et déplacement temporel | Partiel | Lecture, arrêt et curseur implémentés ; non compilés ni testés sur appareil. |
| Renommage et suppression | Partiel | Présents ; suppression fichier/index non transactionnelle. |
| Recherche et organisation | Partiel | Recherche par titre ; transcriptions, dossiers et tags absents. |
| Import audio | Partiel | Sélection et copie locales, validation par le lecteur ; formats et comportement non testés sur appareil. |
| App Intents, Raccourcis et bouton Action | À faire | |
| Live Activity et Dynamic Island | À faire | |
| Transcription Apple Speech | À faire | Capacités et limites à vérifier. |
| Transcription OpenAI | À faire | |
| Correction et accès aux segments | À faire | Modèles partiels sans parcours utilisateur. |
| Diarisation et noms des intervenants | À faire | |
| Fichiers longs et assemblage | À faire | Découpage et décalages temporels absents. |
| Résumés OpenAI, Anthropic et Gemini | À faire | |
| Modèles et validation des comptes rendus | À faire | |
| Clés BYOK et Keychain | À faire | Aucune clé requise pour le prototype actuel. |
| Consentement aux traitements distants | À faire | Aucun traitement distant actuellement. |
| File persistante et reprise des traitements | À faire | États esquissés ; orchestration absente. |
| Exports audio, texte, Markdown, JSON et PDF | À faire | |
| Accessibilité | Partiel | Quelques libellés ; VoiceOver et grandes tailles non testés. |
| Protection et confidentialité des données | À compléter | Protection des fichiers, suppression et sauvegarde iOS à vérifier. |
| Documentation | Partiel | README et architecture présents ; guides et recette complète à rédiger. |
| CI macOS | Configurée, non exécutée | Workflow présent ; compilation et tests non validés. |
| Tests d’intégration et d’interface | À faire | |
| Recette sur iPhone physique | À faire | Microphone, verrouillage et parcours système non validés. |
