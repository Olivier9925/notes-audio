import Foundation
import AVFoundation
import Speech

@MainActor
final class LiveTranscription: ObservableObject {
    @Published var text = ""
    @Published var status = "Prêt"
    @Published var isRunning = false
    @Published var isStarting = false
    @Published var error: String?
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var runID = UUID()
    private var tapInstalled = false
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))

    func start() async {
        guard !isRunning, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        let id = UUID(); runID = id
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard runID == id else { return }
        guard speech == .authorized else { error = "Autorisez la reconnaissance vocale dans Réglages."; return }
        let microphone = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard runID == id else { return }
        guard microphone else { error = "Autorisez le microphone dans Réglages."; return }
        guard let recognizer, recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            error = "La reconnaissance vocale sur cet appareil est indisponible pour le français. Aucun audio n’a été envoyé à un service distant."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            self.request = request
            let prefix = text.trimmingCharacters(in: .whitespacesAndNewlines)
            task = recognizer.recognitionTask(with: request) { [weak self] result, failure in
                let recognized = result?.bestTranscription.formattedString
                let finished = result?.isFinal ?? false
                Task { @MainActor [weak self] in
                    guard let self, self.runID == id else { return }
                    if let recognized { self.text = prefix.isEmpty ? recognized : prefix + "\n" + recognized }
                    if failure != nil { self.finish(); self.error = "La transcription s’est interrompue. Le texte reconnu reste disponible." }
                    else if finished { self.finish() }
                }
            }
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            tapInstalled = true
            engine.prepare()
            try engine.start()
            isRunning = true; status = "Transcription en cours sur l’appareil"
        } catch {
            finish(); self.error = "Impossible de démarrer le microphone ou la reconnaissance vocale."
        }
    }
    func stop() { finish() }
    private func finish() {
        runID = UUID()
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        engine.stop(); request?.endAudio(); task?.cancel()
        request = nil; task = nil; isRunning = false; status = "Arrêtée"
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
