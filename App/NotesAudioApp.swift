import SwiftUI
import NotesAudioDomain

@main
struct NotesAudioApp: App {
    @StateObject private var store = RecordingStore()
    var body: some Scene { WindowGroup { LibraryView().environmentObject(store) } }
}

struct LibraryView: View {
    @EnvironmentObject private var store: RecordingStore
    @State private var search = ""
    @State private var editing: Recording?
    @State private var title = ""
    var body: some View {
        NavigationStack {
            List {
                Section("Enregistrement") {
                    Text(store.status).accessibilityLabel("État : \(store.status)")
                    Text(Duration.seconds(store.elapsed).formatted(.time(pattern: .minuteSecond)))
                        .monospacedDigit().accessibilityLabel("Durée : \(Int(store.elapsed)) secondes")
                    ProgressView(value: Double(store.level)).accessibilityLabel("Niveau sonore")
                    HStack {
                        Button("Démarrer") { Task { await store.start() } }
                        Button("Pause") { store.pause() }
                        Button("Reprendre") { store.resume() }
                    }
                    HStack {
                        Button("Marqueur") { store.mark() }
                        Button("Arrêter") { store.stop() }
                    }
                    Text("Informez les personnes concernées et respectez leur consentement.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Bibliothèque") {
                    let filtered = store.recordings.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }
                    if filtered.isEmpty { Text("Aucun enregistrement disponible.").foregroundStyle(.secondary) }
                    ForEach(filtered) { item in
                        VStack(alignment: .leading) {
                            Text(item.title).font(.headline)
                            Text(item.createdAt, style: .date).font(.caption)
                            HStack {
                                Button(store.playingID == item.id ? "Arrêter la lecture" : "Écouter") {
                                    if store.playingID == item.id { store.stopPlayback() } else { store.play(item) }
                                }
                                Button("Renommer") { title = item.title; editing = item }
                                Button("Supprimer", role: .destructive) { store.delete(item) }
                            }.buttonStyle(.borderless)
                        }
                    }
                }
                Section("Fonctions à venir") { Text("Import, transcription, intervenants, résumés et export ne sont pas encore disponibles.") }
            }
            .navigationTitle("Notes Audio")
            .searchable(text: $search, prompt: "Rechercher un titre")
            .alert("Renommer", isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
                TextField("Titre", text: $title)
                Button("Enregistrer") { if let editing, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { store.rename(editing, title: title) }; editing = nil }
                Button("Annuler", role: .cancel) { editing = nil }
            }
            .alert("Erreur", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
        }
    }
}
