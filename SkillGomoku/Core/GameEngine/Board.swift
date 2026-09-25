import Foundation

struct Board: Codable, Equatable, Sendable {
    static let standardSize = 15

    let size: Int
    private(set) var cells: [Stone?]

    init(size: Int = Board.standardSize, cells: [Stone?]? = nil) {
        precondition(size > 0, "Board size must be positive")
        self.size = size
        self.cells = cells ?? Array(repeating: nil, count: size * size)
    }

    func contains(_ coordinate: Coordinate) -> Bool {
        coordinate.row >= 0 && coordinate.row < size && coordinate.column >= 0 && coordinate.column < size
    }

    subscript(_ coordinate: Coordinate) -> Stone? {
        guard contains(coordinate) else { return nil }
        return cells[index(for: coordinate)]
    }

    func isEmpty(at coordinate: Coordinate) -> Bool {
        contains(coordinate) && self[coordinate] == nil
    }

    var isFull: Bool {
        !cells.contains { $0 == nil }
    }

    var occupiedCount: Int {
        cells.reduce(0) { $0 + ($1 == nil ? 0 : 1) }
    }

    mutating func place(_ stone: Stone, at coordinate: Coordinate) throws {
        guard contains(coordinate) else { throw RuleEngineError.coordinateOutOfBounds }
        guard self[coordinate] == nil else { throw RuleEngineError.positionOccupied }
        cells[index(for: coordinate)] = stone
    }

    @discardableResult
    mutating func removeStone(at coordinate: Coordinate) throws -> Stone {
        guard contains(coordinate) else { throw RuleEngineError.coordinateOutOfBounds }
        guard let stone = self[coordinate] else { throw RuleEngineError.positionEmpty }
        cells[index(for: coordinate)] = nil
        return stone
    }

    mutating func setStone(_ stone: Stone?, at coordinate: Coordinate) throws {
        guard contains(coordinate) else { throw RuleEngineError.coordinateOutOfBounds }
        cells[index(for: coordinate)] = stone
    }

    @discardableResult
    mutating func moveStone(from origin: Coordinate, to destination: Coordinate) throws -> Stone {
        guard contains(origin), contains(destination) else { throw RuleEngineError.coordinateOutOfBounds }
        guard isEmpty(at: destination) else { throw RuleEngineError.positionOccupied }
        let stone = try removeStone(at: origin)
        cells[index(for: destination)] = stone
        return stone
    }

    mutating func removeAllStones() -> [(coordinate: Coordinate, stone: Stone)] {
        var removed: [(coordinate: Coordinate, stone: Stone)] = []
        for offset in cells.indices {
            guard let stone = cells[offset] else { continue }
            cells[offset] = nil
            removed.append((Coordinate(row: offset / size, column: offset % size), stone))
        }
        return removed
    }

    func coordinates(for side: PlayerSide) -> [Coordinate] {
        cells.enumerated().compactMap { offset, stone in
            guard stone?.side == side else { return nil }
            return Coordinate(row: offset / size, column: offset % size)
        }
    }

    var occupiedCoordinates: [Coordinate] {
        cells.enumerated().compactMap { offset, stone in
            guard stone != nil else { return nil }
            return Coordinate(row: offset / size, column: offset % size)
        }
    }

    private func index(for coordinate: Coordinate) -> Int {
        coordinate.row * size + coordinate.column
    }
}
