import Foundation

enum RuleEngineError: Error, Equatable, LocalizedError {
    case coordinateOutOfBounds
    case positionOccupied
    case matchAlreadyFinished
    case notPlayersTurn
    case unsupportedActionInCurrentMode

    var errorDescription: String? {
        switch self {
        case .coordinateOutOfBounds: "落点超出棋盘"
        case .positionOccupied: "这里已经有棋子"
        case .matchAlreadyFinished: "对局已经结束"
        case .notPlayersTurn: "还没轮到这位玩家"
        case .unsupportedActionInCurrentMode: "当前模式暂不支持这个动作"
        }
    }
}

struct RuleEngine: Sendable {
    private let winDetector: WinDetector

    init(winDetector: WinDetector = WinDetector()) {
        self.winDetector = winDetector
    }

    func applying(_ action: GameAction, to state: GameState) throws -> GameState {
        guard !state.status.isFinished else { throw RuleEngineError.matchAlreadyFinished }

        switch action {
        case let .placeStone(coordinate, side):
            guard side == state.currentPlayer else { throw RuleEngineError.notPlayersTurn }
            var next = state
            try next.board.place(Stone(side: side, moveNumber: state.turnCount), at: coordinate)

            if winDetector.hasFiveOrMore(on: next.board, for: side, from: coordinate) {
                next.status = .won(winner: side, reason: .fiveInRow)
            } else if next.board.isFull {
                next.status = .draw(reason: .boardFull)
            } else {
                next.currentPlayer = side.opponent
                next.turnCount += 1
            }

            return next
        }
    }
}
