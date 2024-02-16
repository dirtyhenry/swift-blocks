/// `CopyUtils` is a utility enum providing functionalities for text manipulation.
public enum CopyUtils {
    // MARK: - Public Methods

    /// Replaces all occurrences of a single quote (') in the input string with a typographic apostrophe (’).
    ///
    /// This method is useful for linting strings to ensure typographic correctness, especially in user-facing text where typography matters for readability and aesthetic.
    ///
    /// - Parameter input: The string to be linted.
    /// - Returns: A new string with all single quotes replaced by typographic apostrophes.
    ///
    /// Usage Example:
    /// ```
    /// let originalText = "It's a beautiful day!"
    /// let lintedText = CopyUtils.lint(input: originalText)
    /// print(lintedText) // Output: "It’s a beautiful day!"
    /// ```
    public static func lint(input: String) -> String {
        input
            .replacingOccurrences(of: "'", with: "’")
    }
}
