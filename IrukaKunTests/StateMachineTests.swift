import XCTest
@testable import IrukaKun

@MainActor
final class StateMachineTests: XCTestCase {
    var stateMachine: StateMachine!

    override func setUp() {
        super.setUp()
        stateMachine = StateMachine()
    }

    func testInitialStateIsIdle() {
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testClickTransitionsToHappy() {
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .happy)
    }

    func testHappyReturnsToIdleAfterDuration() {
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .happy)
        stateMachine.handleEvent(.temporaryStateExpired)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testDragTransitionsToSurprised() {
        stateMachine.handleEvent(.dragStarted)
        XCTAssertEqual(stateMachine.currentState, .surprised)
    }

    func testSurprisedReturnsToIdleAfterDuration() {
        stateMachine.handleEvent(.dragStarted)
        stateMachine.handleEvent(.temporaryStateExpired)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testNightTimeTransitionsToSleeping() {
        stateMachine.handleEvent(.nightTime)
        XCTAssertEqual(stateMachine.currentState, .sleeping)
    }

    func testDayTimeReturnsSleepingToIdle() {
        stateMachine.handleEvent(.nightTime)
        stateMachine.handleEvent(.dayTime)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testIdleTimeoutTransitionsToBored() {
        stateMachine.handleEvent(.idleTimeout)
        XCTAssertEqual(stateMachine.currentState, .bored)
    }

    func testClickFromBoredTransitionsToHappy() {
        stateMachine.handleEvent(.idleTimeout)
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .happy)
    }

    func testSleepingIgnoresClickAndDrag() {
        stateMachine.handleEvent(.nightTime)
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .sleeping)
        stateMachine.handleEvent(.dragStarted)
        XCTAssertEqual(stateMachine.currentState, .sleeping)
    }

    func testStateChangeCallback() {
        var receivedStates: [CharacterState] = []
        stateMachine.onStateChanged = { newState in
            receivedStates.append(newState)
        }
        stateMachine.handleEvent(.clicked)
        stateMachine.handleEvent(.temporaryStateExpired)
        XCTAssertEqual(receivedStates, [.happy, .idle])
    }
}
