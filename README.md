# Notes Audio

Prototype initial d’une application iOS native, personnelle et locale. **Le parcours audio local est une première implémentation non compilée et non validée sur appareil.** La transcription, les résumés et les exports restent à développer.

## Projet

Sur Mac avec Xcode et XcodeGen (configuration initialement prévue pour 2.42.0 ; version non vérifiée dans cet environnement) : `xcodegen generate`, puis ouvrir `NotesAudio.xcodeproj`. La configuration de référence est `project.yml` ; le projet généré ne doit pas être maintenu séparément. Compiler pour simulateur avec `xcodebuild -project NotesAudio.xcodeproj -scheme NotesAudio -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build`. Exécuter les tests portables avec `swift test`.

iOS 17 est provisoirement retenu pour l’interface initiale et devra être réévalué lors de l’intégration des API système. L’installation sur appareil nécessite une équipe Apple et une signature configurées séparément.

## État de validation

Le développement initial a été effectué sous Linux sans Swift, Xcode, SDK Apple ou simulateur. Ni la compilation ni les tests n’ont été exécutés. Aucun accès à un microphone, fournisseur IA ou appareil physique n’a été validé. Voir [architecture et travail restant](docs/architecture.md).
