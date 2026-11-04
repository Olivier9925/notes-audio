import SwiftUI

@main
struct NotesAudioApp: App {
    @StateObject private var transcription = LiveTranscription()
    @StateObject private var notes = NoteStore()
    var body: some Scene { WindowGroup { NotesView().environmentObject(transcription).environmentObject(notes) } }
}

struct NotesView: View {
    @EnvironmentObject private var transcription: LiveTranscription
    @EnvironmentObject private var notes: NoteStore
    @State private var search = ""
    @State private var selectedID: UUID?
    @State private var pendingDeletion: Note?
    @State private var showingEditor = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Nouvelle transcription") {
                        selectedID = nil; transcription.text = ""; showingEditor = true
                    }
                }
                Section("Notes locales") {
                    let filtered = notes.notes.filter { search.isEmpty || $0.text.localizedCaseInsensitiveContains(search) }
                    if filtered.isEmpty { Text("Aucune note disponible.").foregroundStyle(.secondary) }
                    ForEach(filtered) { note in
                        HStack {
                            Button {
                                selectedID = note.id; transcription.text = note.text; showingEditor = true
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(note.title).font(.headline)
                                    Text(note.updatedAt, style: .date).font(.caption)
                                }
                            }
                            Spacer()
                            Button("Supprimer", role: .destructive) { pendingDeletion = note }.buttonStyle(.borderless)
                        }
                    }
                }
            }
            .navigationTitle("Notes Audio")
            .searchable(text: $search, prompt: "Rechercher dans les notes")
            .navigationDestination(isPresented: $showingEditor) { TranscriptionView(noteID: $selectedID) }
            .confirmationDialog("Supprimer cette note ?", isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }), titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) { if let note = pendingDeletion { notes.delete(note) }; pendingDeletion = nil }
                Button("Annuler", role: .cancel) { pendingDeletion = nil }
            } message: { Text("Cette action supprime la note locale.") }
            .alert("Notes", isPresented: Binding(get: { notes.error != nil }, set: { if !$0 { notes.error = nil } })) {
                Button("OK") { notes.error = nil }
            } message: { Text(notes.error ?? "") }
        }
    }
}

struct TranscriptionView: View {
    @EnvironmentObject private var transcription: LiveTranscription
    @EnvironmentObject private var notes: NoteStore
    @Binding var noteID: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var savedText = ""
    @State private var confirmDiscard = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(transcription.status).accessibilityLabel("État : \(transcription.status)")
            Text("Le son est transcrit sur cet appareil. Aucun fichier audio n’est créé. La reconnaissance peut s’interrompre et sa disponibilité dépend de l’appareil.")
                .font(.footnote).foregroundStyle(.secondary)
            Text("Informez les personnes concernées et respectez leur consentement.").font(.footnote).foregroundStyle(.secondary)
            HStack {
                Button("Démarrer") { Task { await transcription.start() } }.disabled(transcription.isRunning || transcription.isStarting)
                Button("Arrêter") { transcription.stop() }.disabled(!transcription.isRunning && !transcription.isStarting)
            }
            TextEditor(text: $transcription.text)
                .accessibilityLabel("Transcription modifiable")
                .disabled(transcription.isRunning || transcription.isStarting)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.3)))
            HStack {
                Button("Sauvegarder") { if let id = notes.save(id: noteID, text: transcription.text) { noteID = id; savedText = transcription.text } }
                    .disabled(transcription.isRunning || transcription.isStarting)
                ShareLink(item: transcription.text) { Label("Partager", systemImage: "square.and.arrow.up") }
                    .disabled(transcription.text.isEmpty || transcription.isRunning || transcription.isStarting)
            }
            Text("Sauvegardez avant de quitter cette note.").font(.caption).foregroundStyle(.secondary)
        }
        .padding().navigationTitle("Transcription")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Retour") {
                    if transcription.isRunning || transcription.isStarting { transcription.stop() }
                    if transcription.text != savedText { confirmDiscard = true } else { dismiss() }
                }
            }
        }
        .onAppear { savedText = transcription.text }
        .confirmationDialog("Quitter sans sauvegarder ?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Supprimer les modifications", role: .destructive) { dismiss() }
            Button("Continuer la modification", role: .cancel) { }
        } message: { Text("Les modifications de cette note ne sont pas sauvegardées.") }
        .onDisappear { transcription.stop() }
        .alert("Transcription", isPresented: Binding(get: { transcription.error != nil || notes.error != nil }, set: { if !$0 { transcription.error = nil; notes.error = nil } })) {
            Button("OK") { transcription.error = nil; notes.error = nil }
        } message: { Text(transcription.error ?? notes.error ?? "") }
    }
}
