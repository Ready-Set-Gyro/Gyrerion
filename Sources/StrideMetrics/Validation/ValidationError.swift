/// An input was rejected because it cannot represent a real measurement.
public enum ValidationError: Error, Sendable, Hashable {
    /// The value is NaN or infinite.
    case notFinite(Field)
    /// The value is below zero.
    case negative(Field)
    /// The value is zero but must be strictly positive.
    case zero(Field)

    /// The input that failed validation.
    public enum Field: Sendable, Hashable {
        case duration
        case distance
        case stepCount
        case speed
    }
}

enum Validate {
    /// Requires a finite value ≥ 0. `-0.0` is accepted as zero.
    static func nonNegative(_ value: Double, _ field: ValidationError.Field) throws(ValidationError) {
        guard value.isFinite else { throw .notFinite(field) }
        guard value >= 0 else { throw .negative(field) }
    }

    /// Requires a finite value > 0.
    static func positive(_ value: Double, _ field: ValidationError.Field) throws(ValidationError) {
        try nonNegative(value, field)
        guard value > 0 else { throw .zero(field) }
    }
}
