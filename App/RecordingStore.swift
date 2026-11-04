import Foundation
import AVFoundation
import SwiftUI
import NotesAudioDomain

@MainActor
final class RecordingStore: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var recordings: [Recording] = []
    @Published var status = "Prêt"
    @Published var elapsed: TimeInterval = 0
    @Published var level: Float = 0
    @Published var error: String?
    @Published var playingID: UUID?
    private var starting = false
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var activeID: UUID?
    private var activeURL: URL?
    private var markers: [Marker] = []
    private let directory: URL
    private var indexURL: URL { directory.appendingPathComponent("recordings.json") }

    override init() {
        directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("NotesAudio", isDirectory: true)
        super.init()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: indexURL.path) {
                recordings = try JSONDecoder().decode([Recording].self, from: Data(contentsOf: indexURL))
            }
        } catch { self.error = "Impossible de charger la bibliothèque : \(error.localizedDescription)" }
        NotificationCenter.default.addObserver(self, selector: #selector(interrupted(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaReset(_:)), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    func start() async {
        guard recorder == nil, !starting else { return }
        starting = true
        defer { starting = false }
        stopPlayback()
        status = "Autorisation du microphone"
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard granted else { status = "Prêt"; error = "Autorisez le microphone dans Réglages pour enregistrer."; return }
        // A second command may have arrived while permission was pending.
        guard recorder == nil, status == "Autorisation du microphone" else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let id = UUID()
            let url = directory.appendingPathComponent(id.uuidString + ".m4a")
            let newRecorder = try AVAudioRecorder(url: url, settings: [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderBitRateKey: 64000])
            newRecorder.delegate = self
            newRecorder.isMeteringEnabled = true
            guard newRecorder.record() else { throw CaptureError.cannotStart }
            activeID = id; activeURL = url; markers = []; recorder = newRecorder
            elapsed = 0; status = "Enregistrement"
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        } catch { status = "Erreur"; self.error = "Démarrage impossible : \(error.localizedDescription)" }
    }
    private enum CaptureError: LocalizedError { case cannotStart; var errorDescription: String? { "Le système audio n’a pas démarré." } }
    private func refresh() {
        guard let recorder else { return }
        elapsed = recorder.currentTime
        recorder.updateMeters()
        level = max(0, min(1, (recorder.averagePower(forChannel: 0) + 60) / 60))
    }
    func pause() { guard let recorder, recorder.isRecording else { return }; refresh(); recorder.pause(); status = "Pause" }
    func resume() { guard let recorder, !recorder.isRecording else { return }; if recorder.record() { status = "Enregistrement" } else { status = "Erreur"; error = "La reprise a échoué." } }
    func mark() { guard recorder != nil else { return }; refresh(); markers.append(Marker(offset: elapsed)) }
    func stop() {
        guard let recorder, let id = activeID, let url = activeURL else { return }
        refresh(); status = "Finalisation"; recorder.stop(); timer?.invalidate(); timer = nil
        self.recorder = nil; activeID = nil; activeURL = nil
        let recording = Recording(id: id, title: "Enregistrement \(recordings.count + 1)", audioFileName: url.lastPathComponent, duration: elapsed, markers: markers)
        recordings.insert(recording, at: 0)
        persist(); status = "Prêt"; level = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    func persist() {
        do { try JSONEncoder().encode(recordings).write(to: indexURL, options: .atomic) }
        catch { self.error = "Sauvegarde impossible : \(error.localizedDescription)" }
    }
    func rename(_ recording: Recording, title: String) {
        guard let i = recordings.firstIndex(where: { $0.id == recording.id }) else { return }
        recordings[i].title = title; persist()
    }
    func delete(_ recording: Recording) {
        guard recording.id != activeID else { return }
        do {
            let url = directory.appendingPathComponent(recording.audioFileName)
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            recordings.removeAll { $0.id == recording.id }; persist()
        } catch { self.error = "Suppression impossible : \(error.localizedDescription)" }
    }
    func play(_ recording: Recording) {
        guard recorder == nil, !starting else { error = "Arrêtez l’enregistrement avant la lecture."; return }
        do {
            player?.stop()
            try AVAudioSession.sharedInstance().setCategory(.playback)
            let newPlayer = try AVAudioPlayer(contentsOf: directory.appendingPathComponent(recording.audioFileName))
            newPlayer.delegate = self
            guard newPlayer.play() else { throw CaptureError.cannotStart }
            player = newPlayer; playingID = recording.id
        } catch { self.error = "Lecture impossible : \(error.localizedDescription)" }
    }
    func stopPlayback() { player?.stop(); player = nil; playingID = nil }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { playingID = nil }
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { self.error = "Erreur d’encodage. Arrêtez et vérifiez l’enregistrement."; status = "Erreur" }
    @objc private func interrupted(_ notification: Notification) {
        guard recorder != nil, let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, raw == AVAudioSession.InterruptionType.began.rawValue else { return }
        recorder?.pause(); status = "Interruption — reprenez manuellement"
    }
    @objc private func routeChanged(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt, raw == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
        if recorder != nil { pause(); status = "Entrée audio déconnectée — vérifiez avant de reprendre" }
        else { stopPlayback() }
    }
    @objc private func mediaReset(_ notification: Notification) {
        if recorder != nil { stop(); status = "Services audio réinitialisés"; error = "Vérifiez le fichier enregistré avant de continuer." }
        stopPlayback()
    }
}
