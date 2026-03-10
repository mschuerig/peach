nonisolated protocol CSVVersionedParser: Sendable {
    var supportedVersion: Int { get }
    func parse(lines: [String]) -> CSVImportParser.ImportResult
}
