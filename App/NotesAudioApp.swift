import SwiftUI

@main
struct NotesAudioApp: App {
    @StateObject private var transcription = LiveTranscription()
    var body: some Scene { WindowGroup { TranscriptionView().environmentObject(transcription) } }
}

struct TranscriptionView: View {
    @EnvironmentObject private var transcription: LiveTranscription
    @AppStorage("savedTranscript") private var savedTranscript = ""
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(transcription.status).accessibilityLabel("État : \(transcription.status)")
                Text("Le son est transcrit sur cet appareil. Aucun fichier audio n’est créé. La reconnaissance peut s’interrompre et sa disponibilité dépend de l’appareil.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Informez les personnes concernées et respectez leur consentement.")
                    .font(.footnote).foregroundStyle(.secondary)
                HStack {
                    Button("Démarrer") { Task { await transcription.start() } }
                        .disabled(transcription.isRunning || transcription.isStarting)
                    Button("Arrêter") { transcription.stop() }
                        .disabled(!transcription.isRunning && !transcription.isStarting)
                }
                TextEditor(text: $transcription.text)
                    .accessibilityLabel("Transcription modifiable")
                    .disabled(transcription.isRunning || transcription.isStarting)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.3)))
                HStack {
                    Button("Sauvegarder le texte") { savedTranscript = transcription.text }
                        .disabled(transcription.isRunning || transcription.isStarting)
                    ShareLink(item: transcription.text) { Label("Partager le texte", systemImage: "square.and.arrow.up") }
                        .disabled(transcription.text.isEmpty || transcription.isRunning)
                }
                Text("La sauvegarde remplace la note locale précédente.").font(.caption).foregroundStyle(.secondary)
            }
            .padding().navigationTitle("Notes Audio")
            .onAppear { transcription.text = savedTranscript }
            .alert("Transcription", isPresented: Binding(get: { transcription.error != nil }, set: { if !$0 { transcription.error = nil } })) {
                Button("OK") { transcription.error = nil }
            } message: { Text(transcription.error ?? "") }
        }
    }
}
