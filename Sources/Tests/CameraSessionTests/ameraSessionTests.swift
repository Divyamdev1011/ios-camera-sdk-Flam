func testUnsupportedFPS() {
    let session = CameraSession()

    XCTAssertThrowsError(
        try session.configure(resolution: .high, fps: 240)
    )
}

func testDelegateQueue() {
    let queue = DispatchQueue(label: "test.queue")
    let expectation = XCTestExpectation(description: "Delegate called")

    let session = CameraSession(delegateQueue: queue)

    class TestDelegate: CameraSessionDelegate {
        let expectation: XCTestExpectation
        init(exp: XCTestExpectation) { self.expectation = exp }

        func cameraSession(_ session: CameraSession,
                           didOutputPixelBuffer buffer: CVPixelBuffer,
                           timestamp: CMTime) {

            dispatchPrecondition(condition: .onQueue(DispatchQueue(label: "test.queue")))
            expectation.fulfill()
        }
    }

    let delegate = TestDelegate(exp: expectation)
    session.delegate = delegate

    session.start()

    wait(for: [expectation], timeout: 5)
}
