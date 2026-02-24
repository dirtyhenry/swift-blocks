public extension String {
    // MARK: - Foreground colors

    var black: StyledText {
        StyledText(self).black
    }

    var red: StyledText {
        StyledText(self).red
    }

    var green: StyledText {
        StyledText(self).green
    }

    var yellow: StyledText {
        StyledText(self).yellow
    }

    var blue: StyledText {
        StyledText(self).blue
    }

    var magenta: StyledText {
        StyledText(self).magenta
    }

    var cyan: StyledText {
        StyledText(self).cyan
    }

    var white: StyledText {
        StyledText(self).white
    }

    // MARK: - Background colors

    var onBlack: StyledText {
        StyledText(self).onBlack
    }

    var onRed: StyledText {
        StyledText(self).onRed
    }

    var onGreen: StyledText {
        StyledText(self).onGreen
    }

    var onYellow: StyledText {
        StyledText(self).onYellow
    }

    var onBlue: StyledText {
        StyledText(self).onBlue
    }

    var onMagenta: StyledText {
        StyledText(self).onMagenta
    }

    var onCyan: StyledText {
        StyledText(self).onCyan
    }

    var onWhite: StyledText {
        StyledText(self).onWhite
    }

    // MARK: - Modifiers

    var bold: StyledText {
        StyledText(self).bold
    }

    var dim: StyledText {
        StyledText(self).dim
    }

    var italic: StyledText {
        StyledText(self).italic
    }

    var underline: StyledText {
        StyledText(self).underline
    }

    var strikethrough: StyledText {
        StyledText(self).strikethrough
    }

    var inverse: StyledText {
        StyledText(self).inverse
    }

    var hidden: StyledText {
        StyledText(self).hidden
    }
}
