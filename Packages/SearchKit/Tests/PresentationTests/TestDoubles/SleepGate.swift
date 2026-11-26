// Lets the first `passingCalls` sleeps return at once; later ones last until their task is cancelled.
actor SleepGate {
    private let passingCalls: Int
    private var calls = 0

    init(passingCalls: Int) {
        self.passingCalls = passingCalls
    }

    func sleep(_ duration: Duration) async throws {
        calls += 1
        guard calls > passingCalls else { return }
        try await Task.sleep(for: .seconds(3600))
    }
}
