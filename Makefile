open: 
	open Package.swift

build:
	swift build --build-tests

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

docs:
	xcodebuild docbuild -scheme "Blocks" -derivedDataPath tmp/derivedDataPath -destination platform=macOS
	rsync -r tmp/derivedDataPath/Build/Products/Debug/Blocks.doccarchive/ .Blocks.doccarchive
	rm -rf tmp/

serve-docs:
	serve --single .Blocks.doccarchive

fetch-json-feed-sample:
	curl https://www.jsonfeed.org/feed.json -o Tests/BlocksTests/Resources/sample-feed.json