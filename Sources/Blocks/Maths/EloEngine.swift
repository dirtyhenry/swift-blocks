import Foundation

/// A structure representing an Elo rating engine.
public struct EloEngine {
    /// The default rating used for players without an initial rating.
    public let defaultRating: Int

    /// The dictionary containing player identifiers as keys and their corresponding ratings.
    public private(set) var ratings: [EloPlayer.ID: Int]

    // MARK: - Creating the engine

    /// Initializes the EloEngine with optional defaultRating and initialRatings.
    ///
    /// - Parameters:
    ///   - defaultRating: The default rating to be assigned to players without an initial rating.
    ///   - initialRatings: Initial ratings for specific players.
    public init(defaultRating: Int = 1500, initialRatings: [EloPlayer.ID: Int] = [:]) {
        self.defaultRating = defaultRating
        ratings = initialRatings
    }

    // MARK: - Running the engine

    /// Updates the ratings of two players based on the result and K-factor.
    ///
    /// - Parameters:
    ///   - playerName1: The name of the first player.
    ///   - playerName2: The name of the second player.
    ///   - result: The outcome of the match.
    ///   - kFactor: The K-factor determining the sensitivity of the rating adjustment.
    public mutating func update(playerName1: String, playerName2: String, result: EloResult, kFactor: Int) {
        let player1 = EloPlayer(name: playerName1, rating: ratings[playerName1] ?? defaultRating)
        let player2 = EloPlayer(name: playerName2, rating: ratings[playerName2] ?? defaultRating)

        let res = updateRatings(
            player1: player1,
            player2: player2,
            result: result,
            kFactor: kFactor
        )

        ratings[playerName1] = player1.rating + res.0
        ratings[playerName2] = player2.rating + res.1
    }

    // MARK: - Querying the state of the engine

    /// Retrieves the ranking of players based on their ratings.
    ///
    /// - Returns: An array of EloPlayer objects sorted by rating in descending order.
    public func ranking() -> [EloPlayer] {
        ratings
            .map { EloPlayer(name: $0.key, rating: $0.value) }
            .sorted()
            .reversed()
    }

    /// Calculates the mean rating of all players.
    ///
    /// - Returns: The mean rating of all players. Returns -1 if there are no ratings.
    public func mean() -> Int {
        guard !ratings.isEmpty else {
            return -1
        }

        let sum = ratings.values.reduce(0, +)
        return sum / ratings.count
    }
}

extension EloEngine: Equatable {}

public struct EloPlayer {
    public let name: String
    public var rating: Int
}

extension EloPlayer: Identifiable {
    public var id: String {
        name
    }
}

extension EloPlayer: CustomStringConvertible {
    public var description: String {
        "\(name): \(rating)"
    }
}

public enum EloResult {
    case player1Wins
    case player2Wins
    case draw

    public static func create(score1: Int, score2: Int) -> Self {
        if score1 == score2 {
            return .draw
        }

        if score1 > score2 {
            return .player1Wins
        }

        return .player2Wins
    }
}

extension EloResult {
    var player1Points: Double {
        switch self {
        case .player1Wins:
            1.0
        case .draw:
            0.5
        case .player2Wins:
            0.0
        }
    }

    var player2Points: Double {
        switch self {
        case .player1Wins:
            0.0
        case .draw:
            0.5
        case .player2Wins:
            1.0
        }
    }
}

func expectedProbability(playerRating: Int, opponentRating: Int) -> Double {
    let exponent = Double(opponentRating - playerRating) / 400.0
    let denominator = 1.0 + pow(10.0, exponent)
    return 1.0 / denominator
}

func updateRatings(player1: EloPlayer, player2: EloPlayer, result: EloResult, kFactor: Int) -> (Int, Int) {
    let expectedProbability1 = expectedProbability(playerRating: player1.rating, opponentRating: player2.rating)
    let expectedProbability2 = expectedProbability(playerRating: player2.rating, opponentRating: player1.rating)

    let actualScore1 = result.player1Points
    let actualScore2 = result.player2Points

    let ratingChange1 = Int(Double(kFactor) * (actualScore1 - expectedProbability1))
    let ratingChange2 = Int(Double(kFactor) * (actualScore2 - expectedProbability2))

    return (ratingChange1, ratingChange2)
}

extension EloPlayer: Comparable {
    public static func < (lhs: EloPlayer, rhs: EloPlayer) -> Bool {
        if lhs.rating != rhs.rating {
            lhs.rating < rhs.rating
        } else {
            lhs.name < rhs.name
        }
    }
}
