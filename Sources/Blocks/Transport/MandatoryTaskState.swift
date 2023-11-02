public enum MandatoryTaskState: Equatable {
    case pending
    case loading
    case success
    case failure(error: String)
}

public extension MandatoryTaskState {
    var systemImage: String {
        switch self {
        case .pending:
            return "circle"
        case .loading:
            return "circle.dotted.circle"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        }
    }
}
