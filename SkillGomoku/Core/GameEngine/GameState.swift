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

    static func newMatch(
        mode: GameMode,
        firstPlayer: PlayerSide,
        skillLoadout: [SkillIdentifier] = SkillIdentifier.defaultAdvancedLoadout,
        randomSeed: UInt64 = 0x5eed
    ) -> GameState {
        let identifiers: [SkillIdentifier]
        switch mode {
        case .classic:
            identifiers = []
        case .standardSkills:
            identifiers = SkillIdentifier.standardLoadout
        case .advancedSkills:
            identifiers = Array(skillLoadout.prefix(3))
        }

        let skillStates: [PlayerSide: [SkillState]]
        if identifiers.isEmpty {
            skillStates = [:]
        } else {
            skillStates = [
                .playerOne: SkillState.loadout(for: identifiers),
                .playerTwo: SkillState.loadout(for: identifiers)
            ]
        }

        return GameState(
            currentPlayer: firstPlayer,
            firstPlayer: firstPlayer,
            mode: mode,
            randomState: randomSeed,
            skillStates: skillStates
        )
    }

    func skillState(for skill: SkillIdentifier, side: PlayerSide) -> SkillState? {
        skillStates[side]?.first { $0.id == skill }
    }
}
