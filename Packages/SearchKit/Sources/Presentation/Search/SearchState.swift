import Domain

public enum SearchState: Equatable, Sendable {
    case idle
    case loading([Track])
    case loaded([Track])
    case empty
    case failed
}
