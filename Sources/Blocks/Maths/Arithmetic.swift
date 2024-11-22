// MARK: - Array Extension for Average Calculation

public extension Collection where Element: AdditiveArithmetic, Element: BinaryInteger {
    /// Computes the average of the array's elements.
    func average() -> Double? {
        guard count > 0 else { return nil }
        return count == 0 ? nil : Double(reduce(Element.zero, +)) / Double(count)
    }
}

public extension Collection where Element: AdditiveArithmetic, Element: FloatingPoint {
    /// Computes the average of the array's elements.
    func average() -> Element? {
        guard count > 0 else { return nil }
        return count == 0 ? nil : reduce(Element.zero, +) / Element(count)
    }
}
