import Foundation

struct Coordinate: Hashable, Codable, Sendable {
    let row: Int
    let column: Int

    init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}
