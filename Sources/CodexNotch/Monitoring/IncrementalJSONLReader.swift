import Foundation

struct FileCursor: Equatable, Sendable {
    var offset: UInt64 = 0
    var remainder = Data()
}

protocol IncrementalReading: Sendable {
    func readNewLines(at url: URL, cursor: inout FileCursor) throws -> [Data]
}

struct IncrementalJSONLReader: IncrementalReading {
    func readNewLines(at url: URL, cursor: inout FileCursor) throws -> [Data] {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let fileSize = try handle.seekToEnd()
        if fileSize < cursor.offset {
            cursor = FileCursor()
        }
        try handle.seek(toOffset: cursor.offset)
        let appended = handle.readDataToEndOfFile()
        cursor.offset = fileSize

        let combined = cursor.remainder + appended
        guard !combined.isEmpty else { return [] }

        let hasTrailingNewline = combined.last == 0x0A
        let pieces = combined.split(separator: 0x0A, omittingEmptySubsequences: false)
        let completePieces: ArraySlice<Data.SubSequence>

        if hasTrailingNewline {
            cursor.remainder = Data()
            completePieces = pieces[...]
        } else {
            cursor.remainder = Data(pieces.last ?? Data())
            completePieces = pieces.dropLast()
        }

        return completePieces
            .filter { !$0.isEmpty }
            .map { Data($0) }
    }
}
