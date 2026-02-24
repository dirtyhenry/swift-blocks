public extension StyledText {
    // MARK: - Foreground colors

    var black: StyledText {
        with(foreground: .black)
    }

    var red: StyledText {
        with(foreground: .red)
    }

    var green: StyledText {
        with(foreground: .green)
    }

    var yellow: StyledText {
        with(foreground: .yellow)
    }

    var blue: StyledText {
        with(foreground: .blue)
    }

    var magenta: StyledText {
        with(foreground: .magenta)
    }

    var cyan: StyledText {
        with(foreground: .cyan)
    }

    var white: StyledText {
        with(foreground: .white)
    }

    // MARK: - Background colors

    var onBlack: StyledText {
        with(background: .black)
    }

    var onRed: StyledText {
        with(background: .red)
    }

    var onGreen: StyledText {
        with(background: .green)
    }

    var onYellow: StyledText {
        with(background: .yellow)
    }

    var onBlue: StyledText {
        with(background: .blue)
    }

    var onMagenta: StyledText {
        with(background: .magenta)
    }

    var onCyan: StyledText {
        with(background: .cyan)
    }

    var onWhite: StyledText {
        with(background: .white)
    }

    // MARK: - Modifiers

    var bold: StyledText {
        with(modifier: .bold)
    }

    var dim: StyledText {
        with(modifier: .dim)
    }

    var italic: StyledText {
        with(modifier: .italic)
    }

    var underline: StyledText {
        with(modifier: .underline)
    }

    var strikethrough: StyledText {
        with(modifier: .strikethrough)
    }

    var inverse: StyledText {
        with(modifier: .inverse)
    }

    var hidden: StyledText {
        with(modifier: .hidden)
    }
}
