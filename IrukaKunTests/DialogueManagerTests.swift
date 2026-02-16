import XCTest
@testable import IrukaKun

final class DialogueManagerTests: XCTestCase {

    func testTimeOfDayClassification() {
        XCTAssertEqual(TimeOfDay.from(hour: 7), .morning)
        XCTAssertEqual(TimeOfDay.from(hour: 9), .morning)
        XCTAssertEqual(TimeOfDay.from(hour: 10), .afternoon)
        XCTAssertEqual(TimeOfDay.from(hour: 14), .afternoon)
        XCTAssertEqual(TimeOfDay.from(hour: 18), .evening)
        XCTAssertEqual(TimeOfDay.from(hour: 23), .evening)
        XCTAssertEqual(TimeOfDay.from(hour: 0), .night)
        XCTAssertEqual(TimeOfDay.from(hour: 5), .night)
    }

    func testLoadDialoguesFromJSON() {
        let manager = DialogueManager()
        let morning = manager.dialogues(for: .morning)
        XCTAssertFalse(morning.isEmpty)
        XCTAssertTrue(morning.contains("おはよう！今日もがんばろう"))
    }

    func testDialogueForEvent() {
        let manager = DialogueManager()
        let clickDialogue = manager.dialogueForEvent(.clicked)
        XCTAssertNotNil(clickDialogue)
    }

    func testDialogueForDragEvent() {
        let manager = DialogueManager()
        let dragDialogue = manager.dialogueForEvent(.dragStarted)
        XCTAssertNotNil(dragDialogue)
    }

    func testDialogueForBoredEvent() {
        let manager = DialogueManager()
        let boredDialogue = manager.dialogueForEvent(.idleTimeout)
        XCTAssertNotNil(boredDialogue)
    }

    func testTimeBasedDialogue() {
        let manager = DialogueManager()
        let dialogue = manager.timeBasedDialogue(hour: 8)
        XCTAssertNotNil(dialogue)
    }

    func testNightTimeDialogue() {
        let manager = DialogueManager()
        let dialogue = manager.timeBasedDialogue(hour: 2)
        XCTAssertNotNil(dialogue)
    }
}
