import Foundation

struct GameState: Codable, Equatable, Sendable {
    var board: Board
    var currentPlayer: PlayerSide
    var firstPlayer: PlayerSide
    var mode: GameMode
    var status: MatchStatus
    var turnCount: Int
    var randomState: UInt64
    var skillStates: [PlayerSide: [SkillState]]
    var removedStones: [RemovedStone]
    var blockedCoordinates: [Coordinate: PlayerSide]
    var protectedCoordinates: [Coordinate: Int]

    init(
        board: Board = Board(),
        currentPlayer: PlayerSide = .playerOne,
        firstPlayer: PlayerSide = .playerOne,
        mode: GameMode = .classic,
        status: MatchStatus = .inProgress,
        turnCount: Int = 1,
        randomState: UInt64 = 0x5eed,
        skillStates: [PlayerSide: [SkillState]] = [:],
        removedStones: [RemovedStone] = [],
        blockedCoordinates: [Coordinate: PlayerSide] = [:],
        protectedCoordinates: [Coordinate: Int] = [:]
    ) {
        self.board = board
        self.currentPlayer = currentPlayer
        self.firstPlayer = firstPlayer
        self.mode = mode
        self.status = status
        self.turnCount = turnCount
        self.randomState = randomState
        self.skillStates = skillStates
        self.removedStones = removedStones
        self.blockedCoordinates = blockedCoordinates
        self.protectedCoordinates = protectedCoordinates
    }

    static func newClassic(firstPlayer: PlayerSide) -> GameState {
        GameState(currentPlayer: firstPlayer, firstPlayer: firstPlayer, mode: .classic)
    }
}
