# Notes Audio

Prototype initial d’une application iOS native, personnelle et locale. **La transcription en direct est une première implémentation non compilée et non validée sur appareil.** Le parcours actif ne crée aucun fichier audio.

## Projet

Sur Mac avec Xcode et XcodeGen (configuration initialement prévue pour 2.42.0 ; version non vérifiée dans cet environnement) : `xcodegen generate`, puis ouvrir `NotesAudio.xcodeproj`. La configuration de référence est `project.yml` ; le projet généré ne doit pas être maintenu séparément. Compiler pour simulateur avec `xcodebuild -project NotesAudio.xcodeproj -scheme NotesAudio -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build`. Exécuter les tests portables avec `swift test`.

iOS 17 est provisoirement retenu pour l’interface initiale et devra être réévalué lors de l’intégration des API système. L’installation sur appareil nécessite une équipe Apple et une signature configurées séparément.

## État de validation

Le développement initial a été effectué sous Linux sans Swift, Xcode, SDK Apple ou simulateur. Ni la compilation ni les tests n’ont été exécutés. Aucun accès à un microphone, fournisseur IA ou appareil physique n’a été validé. Voir [architecture et travail restant](docs/architecture.md).

## Avancement des fonctionnalités

Le produit est réorienté vers la transcription en direct sans création de fichier audio. Mettre ce tableau à jour à chaque évolution. Les fonctionnalités ci-dessous ne sont pas compilées ni testées sur appareil.

| Fonctionnalité | État | Limites |
|---|---|---|
| Transcription vocale en direct | Première implémentation | Apple Speech en français, reconnaissance sur appareil requise ; disponibilité et durée variables, sans validation sur iPhone. |
| Microphone sans fichier audio | Première implémentation | Tampons transmis au moteur Speech ; aucun fichier audio créé dans ce parcours. |
| Correction et partage du texte | Première implémentation | Édition après arrêt et partage système ; non testés. |
| Sauvegarde locale | Partiel | Plusieurs notes dans un fichier JSON atomique ; confirmation avant de quitter avec des changements non sauvegardés. Aucune sauvegarde automatique après fermeture forcée ; non testé. |
| Autorisations et erreurs | Partiel | Autorisations, interruptions audio, déconnexion et réinitialisation gérées ; non compilées ni testées sur appareil. |
| Bibliothèque de notes, recherche et suppression | Partiel | Liste, recherche dans le texte et suppression confirmée implémentées ; non compilées ni testées. |
| Diarisation et horodatage | À faire | Aucune attribution d’intervenant n’est inventée. |
| Résumés IA et clés personnelles | À faire | Aucun traitement distant implémenté. |
| Raccourcis, bouton Action et Live Activity | À réévaluer | Les anciennes exigences supposaient un enregistrement audio. |
| Tests et compilation | Non exécutés | Swift et Xcode indisponibles dans cet environnement. |
| Ancien code d’enregistrement | Conservé, inaccessible dans l’interface | Les anciens fichiers ne sont ni supprimés ni migrés automatiquement. |
