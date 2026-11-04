import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var updatedAt: Date
    var title: String {
        let first = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        return first.isEmpty ? "Note sans titre" : String(first.prefix(80))
    }
}

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [Note] = []
    @Published var error: String?
    private(set) var available = false
    private let url: URL
    private let legacyKey = "savedTranscript"

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("NotesAudioNotes", isDirectory: true)
        url = directory.appendingPathComponent("notes.json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: url.path) {
                notes = try JSONDecoder().decode([Note].self, from: Data(contentsOf: url))
            } else if let legacy = UserDefaults.standard.string(forKey: legacyKey), !legacy.isEmpty {
                let initial = [Note(id: UUID(), text: legacy, updatedAt: Date())]
                try write(initial)
                notes = initial
                UserDefaults.standard.removeObject(forKey: legacyKey)
            }
            available = true
        } catch {
            self.error = "Impossible de charger les notes. Les modifications sont désactivées pour protéger les données."
        }
    }
    private func write(_ updated: [Note]) throws {
        try JSONEncoder().encode(updated).write(to: url, options: .atomic)
    }
    func save(id: UUID?, text: String) -> UUID? {
        guard available else { error = "Bibliothèque indisponible."; return nil }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = "La note est vide."; return nil }
        var updated = notes
        let result: UUID
        if let id {
            guard let index = updated.firstIndex(where: { $0.id == id }) else { error = "Cette note n’existe plus."; return nil }
            updated[index].text = text; updated[index].updatedAt = Date(); result = id
        } else {
            result = UUID(); updated.insert(Note(id: result, text: text, updatedAt: Date()), at: 0)
        }
        do { try write(updated); notes = updated; return result }
        catch { self.error = "Impossible de sauvegarder la note. Le texte reste ouvert."; return nil }
    }
    func delete(_ note: Note) {
        guard available else { error = "Bibliothèque indisponible."; return }
        let updated = notes.filter { $0.id != note.id }
        do { try write(updated); notes = updated }
        catch { self.error = "Impossible de supprimer la note." }
    }
}
