import Foundation

enum ImportParserError: LocalizedError {
    case unsupportedFormat
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: "The selected file format is not supported by this template."
        case .invalidJSON: "The JSON file must contain an object or an array of objects."
        }
    }
}

enum ImportParser {
    nonisolated static func parse(data: Data, template: ImportTemplate) throws -> [ImportedHealthRecord] {
        switch template.format {
        case .csv:
            return try parseRows(CSVTable(data: data).rows, template: template)
        case .json:
            return try parseRows(jsonRows(data: data), template: template)
        }
    }

    nonisolated static func supplementalMetrics(data: Data, template: ImportTemplate) throws -> [SupplementalMetric] {
        switch template.format {
        case .csv:
            return []
        case .json:
            return try jsonMetricRows(data: data).flatMap { supplementalMetrics(from: $0, template: template) }
        }
    }

    private nonisolated static func parseRows(_ rows: [[String: String]], template: ImportTemplate) throws -> [ImportedHealthRecord] {
        var records: [ImportedHealthRecord] = []

        for row in rows {
            guard let date = date(from: row, template: template) else { continue }

            for mapping in template.mappings {
                guard let raw = row[mapping.sourceKey], let value = Double(raw.trimmedNumericString) else { continue }
                records.append(
                    ImportedHealthRecord(
                        date: date,
                        metric: mapping.metric,
                        value: mapping.metric.normalizedHealthKitValue(from: value),
                        sourceKey: mapping.sourceKey,
                        sourceName: template.name
                    )
                )
            }
        }

        return records.sorted { $0.date > $1.date }
    }

    private nonisolated static func supplementalMetrics(from row: [String: Any], template: ImportTemplate) -> [SupplementalMetric] {
        let stringValues = stringRow(row)
        guard let date = date(from: stringValues, template: template) else { return [] }

        let mappedSourceKeys = Set(template.mappings.map(\.sourceKey))
        var metrics: [SupplementalMetric] = []

        if let bwiScore = row["bwiScore"] {
            metrics.append(
                SupplementalMetric(
                    date: date,
                    section: "BWI Result",
                    name: "BWI Result",
                    value: "\(bwiScore)",
                    status: nil,
                    isHealthKitMapped: false
                )
            )
        }

        guard let nestedMetrics = row["metrics"] as? [[String: Any]] else {
            return metrics
        }

        metrics.append(contentsOf: nestedMetrics.compactMap { metric in
            guard let name = metric["metric"].flatMap(Self.stringValue),
                  let value = metric["value"].flatMap(Self.stringValue),
                  !name.isEmpty,
                  !value.isEmpty else {
                return nil
            }

            let status = metric["status"]
                .flatMap(Self.stringValue)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return SupplementalMetric(
                date: date,
                section: metric["section"].flatMap(Self.stringValue) ?? "Other",
                name: name,
                value: value,
                status: status?.isEmpty == false ? status : nil,
                isHealthKitMapped: mappedSourceKeys.contains(name)
            )
        })

        return metrics
    }

    private nonisolated static func jsonRows(data: Data) throws -> [[String: String]] {
        try jsonMetricRows(data: data).map(stringRow)
    }

    private nonisolated static func jsonMetricRows(data: Data) throws -> [[String: Any]] {
        let object = try JSONSerialization.jsonObject(with: data)
        if let rows = object as? [[String: Any]] {
            return rows
        }
        if let row = object as? [String: Any] {
            if let nestedRows = row["data"] as? [[String: Any]] {
                return nestedRows
            }
            if let nestedRows = row["records"] as? [[String: Any]] {
                return nestedRows
            }
            return [row]
        }
        throw ImportParserError.invalidJSON
    }

    private nonisolated static func stringRow(_ row: [String: Any]) -> [String: String] {
        var result = row.reduce(into: [String: String]()) { partialResult, pair in
            guard pair.key != "metrics" else { return }
            partialResult[pair.key] = "\(pair.value)"
        }

        if let metrics = row["metrics"] as? [[String: Any]] {
            for metric in metrics {
                guard let name = metric["metric"] as? String,
                      let value = metric["value"] else {
                    continue
                }
                result[name] = "\(value)"
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

    private nonisolated static func date(from row: [String: String], template: ImportTemplate) -> Date? {
        guard let datePart = row[template.dateKey]?.trimmingCharacters(in: .whitespacesAndNewlines), !datePart.isEmpty else {
            return nil
        }

        let value: String
        if let timeKey = template.timeKey, let timePart = row[timeKey]?.trimmingCharacters(in: .whitespacesAndNewlines), !timePart.isEmpty {
            value = "\(datePart) \(timePart)"
        } else {
            value = datePart
        }

        if let unix = Double(value), unix > 1_000_000_000 {
            return Date(timeIntervalSince1970: unix)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current

        for format in template.dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return ISO8601DateFormatter().date(from: value)
    }
}

private struct CSVTable {
    let rows: [[String: String]]

    nonisolated init(data: Data) {
        let text = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "\u{feff}", with: "")
        let parsedRows = Self.parse(text)
        guard let header = parsedRows.first else {
            rows = []
            return
        }

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

private extension String {
    nonisolated var trimmedNumericString: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.-").inverted)
            .joined()
    }
}
