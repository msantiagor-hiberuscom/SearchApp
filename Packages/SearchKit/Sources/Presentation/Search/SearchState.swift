import Domain

public enum SearchState: Equatable, Sendable {
    case idle
    case loading
    case loaded([Track])
    case empty
    case failed
}
