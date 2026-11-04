import Foundation

public struct Marker: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var offset: TimeInterval
    public init(id: UUID = UUID(), offset: TimeInterval) {
        self.id = id
        self.offset = max(0, offset)
    }
}

public struct TranscriptSegment: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var start: TimeInterval
    public var end: TimeInterval
    public var text: String
    public var speakerID: UUID?
    public init(id: UUID = UUID(), start: TimeInterval, end: TimeInterval, text: String, speakerID: UUID? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.text = text
        self.speakerID = speakerID
    }
}

public struct Transcript: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var segments: [TranscriptSegment]
    public init(id: UUID = UUID(), createdAt: Date = Date(), segments: [TranscriptSegment]) {
        self.id = id
        self.createdAt = createdAt
        self.segments = segments
    }
}

public struct Recording: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var audioFileName: String
    public var duration: TimeInterval
    public var markers: [Marker]
    public var transcripts: [Transcript]
    public init(id: UUID = UUID(), title: String, createdAt: Date = Date(), audioFileName: String, duration: TimeInterval, markers: [Marker] = [], transcripts: [Transcript] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.audioFileName = audioFileName
        self.duration = duration
        self.markers = markers
        self.transcripts = transcripts
    }
}

public enum ProcessingState: String, Codable, Sendable {
    case pending, running, interrupted, completed, failed, cancelled
}

public protocol RecordingRepository: Sendable {
    func list() async throws -> [Recording]
    func save(_ recording: Recording) async throws
    func delete(id: UUID) async throws
}
