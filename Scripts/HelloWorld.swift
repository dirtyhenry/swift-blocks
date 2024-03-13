#!/usr/bin/swift

func greet(name: String) {
    print("Hello \(name)")
}

if CommandLine.argc != 2 {
    print("Usage: ./\(CommandLine.arguments[0]) name")
} else {
    greet(name: CommandLine.arguments[1])
}

