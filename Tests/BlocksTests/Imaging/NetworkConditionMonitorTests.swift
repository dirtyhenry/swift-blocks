#if canImport(Network)

@testable import Blocks
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
final class NetworkConditionMonitorTests: XCTestCase {
    func testPresetForExcellent() {
        let preset = CompressionPreset.preset(for: .excellent)
        let config = preset.configuration
        XCTAssertEqual(config.targetByteSize, 2_000_000)
        XCTAssertEqual(config.maxWidth, 4096)
    }

    func testPresetForGood() {
        let preset = CompressionPreset.preset(for: .good)
        let config = preset.configuration
        XCTAssertEqual(config.targetByteSize, 800_000)
        XCTAssertEqual(config.maxWidth, 2048)
    }

    func testPresetForPoor() {
        let preset = CompressionPreset.preset(for: .poor)
        let config = preset.configuration
        XCTAssertEqual(config.targetByteSize, 300_000)
        XCTAssertEqual(config.maxWidth, 1024)
    }

    func testPresetForOffline() {
        let preset = CompressionPreset.preset(for: .offline)
        let config = preset.configuration
        XCTAssertEqual(config.targetByteSize, 300_000)
    }

    func testMonitorInitialConditionIsOffline() {
        let monitor = NetworkConditionMonitor()
        XCTAssertEqual(monitor.currentCondition, .offline)
    }

    func testEachStreamFirstGivesTheCurrentCondition() async {
        let monitor = NetworkConditionMonitor()
        var first = monitor.conditions.makeAsyncIterator()
        var second = monitor.conditions.makeAsyncIterator()

        let firstValue = await first.next()
        let secondValue = await second.next()
        XCTAssertEqual(firstValue, .offline)
        XCTAssertEqual(secondValue, .offline)
    }

    func testStopFinishesTheStreams() async {
        let monitor = NetworkConditionMonitor()
        var before = monitor.conditions.makeAsyncIterator()
        monitor.stop()
        var after = monitor.conditions.makeAsyncIterator()

        let beforeValues = await [before.next(), before.next()]
        let afterValues = await [after.next(), after.next()]
        XCTAssertEqual(beforeValues, [.offline, nil])
        XCTAssertEqual(afterValues, [.offline, nil])
    }

    func testCompressionPresetConfigurations() {
        XCTAssertEqual(CompressionPreset.highQuality.configuration.targetByteSize, 2_000_000)
        XCTAssertEqual(CompressionPreset.balanced.configuration.targetByteSize, 800_000)
        XCTAssertEqual(CompressionPreset.compact.configuration.targetByteSize, 300_000)
    }

    func testCustomPreset() {
        let config = ImageCompressor.Configuration(targetByteSize: 100_000, maxWidth: 512, maxHeight: 512)
        let preset = CompressionPreset.custom(config)
        XCTAssertEqual(preset.configuration.targetByteSize, 100_000)
        XCTAssertEqual(preset.configuration.maxWidth, 512)
    }
}

#endif
