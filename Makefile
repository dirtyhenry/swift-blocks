open: 
	open Package.swift

build:
	swift build

test:
	swift test

release:
	swift build -c release

format:
	swiftformat --verbose .
	swiftlint lint --autocorrect .
	
lint:
	swiftformat --lint .
	swiftlint lint .

clean:
	rm -rf .build/