open: 
	open Blocks.xcworkspace

install:
	bundle install
	swift package resolve

build:
	swift build

cli:
	swift package update --package-path Examples/BlocksCLI/
	swift build --package-path Examples/BlocksCLI/

build-ios:
	xcrun xcodebuild clean build -scheme Blocks -destination generic/platform=ios
	xcrun xcodebuild clean build -scheme ObjectiveBlocks -destination generic/platform=ios

test-debug:
	swift package clean
	swift test --verbose --very-verbose

test:
	set -o pipefail && swift test | xcpretty

test-ios:
	xcrun xcodebuild clean test -scheme Blocks -destination "platform=iOS Simulator,OS=17.0.1"

release:
	swift build -c release

format:
	swiftformat --verbose .
	swiftlint lint --autocorrect .
	
lint:
	swiftformat --lint .
	swiftlint lint .

clean:
	find . -type d -name '.build' -exec rm -rfv {} +
	find . -type d -name '.swiftpm' -exec rm -rfv {} +

docs:
	xcodebuild docbuild -scheme "Blocks" -derivedDataPath tmp/derivedDataPath -destination platform=macOS
	rsync -r tmp/derivedDataPath/Build/Products/Debug/Blocks.doccarchive/ .Blocks.doccarchive
	rm -rf tmp/

serve-docs:
	serve --single .Blocks.doccarchive

fetch-json-feed-sample:
	curl https://www.jsonfeed.org/feed.json -o Tests/BlocksTests/Resources/sample-feed.json

dump-packages:
	swift package dump-package > Tests/BlocksTests/Resources/dump-package.json 
	prettier -w Tests/BlocksTests/Resources/dump-package.json

build-linux-dev:
	docker build -t swift-blocks .

test-linux-dev:
	docker run swift-blocks