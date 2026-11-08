import Blocks
import XCTest

final class EloEngineTests: XCTestCase {
    func testEvenPlayersSplitTheKFactor() {
        var engine = EloEngine()
        engine.update(playerName1: "A", playerName2: "B", result: .player1Wins, kFactor: 32)
        XCTAssertEqual(engine.ratings, ["A": 1516, "B": 1484])
    }

    func testAnUpsetMovesBothRatings() {
        // A is expected to win 76% of the time: 1 / (1 + 10^(-200 / 400)).
        var engine = EloEngine(initialRatings: ["A": 1600, "B": 1400])
        engine.update(playerName1: "A", playerName2: "B", result: .player2Wins, kFactor: 20)
        XCTAssertEqual(engine.ratings, ["A": 1585, "B": 1415])
        XCTAssertEqual(engine.ranking().map(\.description), ["A: 1585", "B: 1415"])
        XCTAssertEqual(engine.mean(), 1500)
    }

    func testResultFromScores() {
        XCTAssertEqual(EloResult.create(score1: 2, score2: 1), .player1Wins)
        XCTAssertEqual(EloResult.create(score1: 1, score2: 1), .draw)
        XCTAssertEqual(EloResult.create(score1: 0, score2: 1), .player2Wins)
    }

    // swiftlint:disable function_body_length
    func testNBA2022RegularSeason() throws {
        let csvDataURL = try XCTUnwrap(Bundle.module.url(forResource: "nba-2022-2023", withExtension: "csv"))
        // Visitor and home teams with their points, columns 2 to 5 of Basketball Reference's export.
        let games = try String(contentsOf: csvDataURL, encoding: .utf8)
            .components(separatedBy: .newlines)
            .filter { !$0.starts(with: "Date") && !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { $0.components(separatedBy: ",") }
        XCTAssertEqual(games.count, 1230)

        var engine = EloEngine(defaultRating: 1500)
        for game in games {
            try engine.update(
                playerName1: game[4],
                playerName2: game[2],
                result: .create(score1: XCTUnwrap(Int(game[5])), score2: XCTUnwrap(Int(game[3]))),
                kFactor: 22
            )
        }

        XCTAssertEqual(engine.ranking().map(\.description).joined(separator: "\n"), """
        Milwaukee Bucks: 1637
        Philadelphia 76ers: 1624
        Boston Celtics: 1622
        Cleveland Cavaliers: 1574
        Memphis Grizzlies: 1568
        Denver Nuggets: 1564
        New York Knicks: 1562
        Los Angeles Lakers: 1562
        Phoenix Suns: 1552
        Golden State Warriors: 1549
        Los Angeles Clippers: 1548
        Sacramento Kings: 1541
        Miami Heat: 1535
        Toronto Raptors: 1528
        Minnesota Timberwolves: 1526
        Brooklyn Nets: 1519
        Chicago Bulls: 1518
        New Orleans Pelicans: 1509
        Oklahoma City Thunder: 1498
        Atlanta Hawks: 1496
        Orlando Magic: 1464
        Utah Jazz: 1435
        Washington Wizards: 1430
        Indiana Pacers: 1423
        Dallas Mavericks: 1420
        Charlotte Hornets: 1417
        Portland Trail Blazers: 1380
        Houston Rockets: 1374
        San Antonio Spurs: 1347
        Detroit Pistons: 1278
        """)
    }
    // swiftlint:enable function_body_length
}
