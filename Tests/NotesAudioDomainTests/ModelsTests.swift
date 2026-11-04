import XCTest
@testable import NotesAudioDomain

final class ModelsTests: XCTestCase {
    func testRecordingRoundTripPreservesTranscriptCorrections() throws {
        let segment = TranscriptSegment(start: 1, end: 2, text: "Texte corrigé")
        let recording = Recording(title: "Réunion", audioFileName: "audio.m4a", duration: 3, transcripts: [Transcript(segments: [segment])])
        let decoded = try JSONDecoder().decode(Recording.self, from: JSONEncoder().encode(recording))
        XCTAssertEqual(decoded, recording)
    }
    func testMarkerOffsetIsNotNegative() {
        XCTAssertEqual(Marker(offset: -1).offset, 0)
    }
}
