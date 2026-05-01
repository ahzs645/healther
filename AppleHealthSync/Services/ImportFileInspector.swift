import Foundation

struct ImportFilePreview: Identifiable, Hashable {
    var id = UUID()
    var fileName: String
    var format: ImportFormat
    var data: Data
    var fields: [ImportSourceField]
    var sampleRows: [[String: String]]

    var suggestedDateKey: String {
        fields.first { field in
            let key = field.name.lowercased()
            return key == "date" || key == "startdate" || key == "start date" || key.contains("start datetime") || key.contains("start date")
        }?.name ?? fields.first?.name ?? "date"
    }

    var suggestedTimeKey: String? {
        fields.first { field in
            let key = field.name.lowercased()
            return key == "time" || key == "starttime" || key == "start time"
        }?.name
    }
}

struct ImportSourceField: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var sampleValue: String
}

enum ImportFileInspectorError: LocalizedError {
    case unsupportedFile
    case emptyFile
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            "Choose a CSV or JSON file."
        case .emptyFile:
            "The selected file does not contain importable fields."
        case .invalidJSON:
            "The JSON file must contain an object, an array of objects, or a top-level data/records array."
        }
    }
}

enum ImportFileInspector {
    nonisolated static func inspect(url: URL) throws -> ImportFilePreview {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let format = try format(for: url)
        let rows: [[String: String]]
        let orderedKeys: [String]

        switch format {
        case .csv:
            let table = CSVPreviewTable(data: data)
            rows = table.rows
            orderedKeys = table.headers
        case .json:
            rows = try jsonRows(data: data)
            orderedKeys = Self.orderedKeys(from: rows)
        }

        let fields = orderedKeys.map { key in
            ImportSourceField(
                name: key,
                sampleValue: rows.first { row in
                    row[key]?.isEmpty == false
                }?[key] ?? ""
            )
        }

        guard !fields.isEmpty else {
            throw ImportFileInspectorError.emptyFile
        }

        return ImportFilePreview(
            fileName: url.lastPathComponent,
            format: format,
            data: data,
            fields: fields,
            sampleRows: Array(rows.prefix(5))
        )
    }

    private nonisolated static func format(for url: URL) throws -> ImportFormat {
        switch url.pathExtension.lowercased() {
        case "csv", "tsv", "txt":
            .csv
        case "json":
            .json
        default:
            throw ImportFileInspectorError.unsupportedFile
        }
    }

    private nonisolated static func jsonRows(data: Data) throws -> [[String: String]] {
        let object = try JSONSerialization.jsonObject(with: data)
        let rows: [[String: Any]]

        if let array = object as? [[String: Any]] {
            rows = array
        } else if let dictionary = object as? [String: Any] {
            if let dataRows = dictionary["data"] as? [[String: Any]] {
                rows = dataRows
            } else if let recordRows = dictionary["records"] as? [[String: Any]] {
                rows = recordRows
            } else {
                rows = [dictionary]
            }
        } else {
            throw ImportFileInspectorError.invalidJSON
        }

        return rows.map(stringRow)
    }

    private nonisolated static func stringRow(_ row: [String: Any]) -> [String: String] {
        var result = row.reduce(into: [String: String]()) { partialResult, pair in
            guard pair.key != "metrics" else { return }
            partialResult[pair.key] = stringValue(pair.value)
        }

        if let metrics = row["metrics"] as? [[String: Any]] {
            for metric in metrics {
                guard let name = metric["metric"].map(stringValue),
                      let value = metric["value"].map(stringValue),
                      !name.isEmpty else {
                    continue
                }
                result[name] = value
            }
        }

        return result
    }

    private nonisolated static func stringValue(_ value: Any) -> String {
        switch value {
        case let string as String:
            string.trimmingCharacters(in: .whitespacesAndNewlines)
        case let number as NSNumber:
            number.stringValue
        default:
            "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private nonisolated static func orderedKeys(from rows: [[String: String]]) -> [String] {
        var seen = Set<String>()
        var keys: [String] = []
        for row in rows {
            for key in row.keys.sorted() where !seen.contains(key) {
                seen.insert(key)
                keys.append(key)
            }
        }
        return keys
    }
}

private struct CSVPreviewTable {
    let headers: [String]
    let rows: [[String: String]]

    nonisolated init(data: Data) {
        let text = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "\u{feff}", with: "")
        let parsedRows = Self.parse(text)
        guard let header = parsedRows.first else {
            headers = []
            rows = []
            return
        }

        headers = header
        rows = parsedRows.dropFirst().map { values in
            Dictionary(uniqueKeysWithValues: header.enumerated().map { index, key in
                (key, index < values.count ? values[index] : "")
            })
        }
    }

    private nonisolated static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var iterator = text.makeIterator()

        while let character = iterator.next() {
            switch character {
            case "\"":
                if isQuoted, let next = iterator.next() {
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        isQuoted.toggle()
                        if next == "," {
                            row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
                            field = ""
                        } else if next == "\n" {
                            row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
                            rows.append(row)
                            row = []
                            field = ""
                        } else {
                            field.append(next)
                        }
                    }
                } else {
                    isQuoted.toggle()
                }
            case "," where !isQuoted:
                row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
                field = ""
            case "\n" where !isQuoted:
                row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
                rows.append(row)
                row = []
                field = ""
            case "\r":
                continue
            default:
                field.append(character)
            }
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
            rows.append(row)
        }

        return rows.filter { !$0.allSatisfy(\.isEmpty) }
    }
}
