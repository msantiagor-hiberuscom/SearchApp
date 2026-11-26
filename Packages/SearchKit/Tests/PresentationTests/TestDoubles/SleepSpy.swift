actor SleepSpy {
    private(set) var durations = [Duration]()
    
    func sleep(_ duration: Duration) async throws {
        durations.append(duration)
    }
}
