import Foundation
import Observation

@Observable
final class TemplateExportStore {
    private let directory: URL

    init() {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HealtherTemplateExports", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func exportURL(for template: ImportTemplate) -> URL? {
        var exportTemplate = template
        exportTemplate.isBuiltIn = false
        exportTemplate.logoImageName = nil

        guard let data = try? JSONEncoder.healtherTemplateEncoder.encode(exportTemplate) else {
            return nil
        }

        let fileName = "\(template.name.slugified)-healther-template.json"
        let url = directory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

extension JSONEncoder {
    static var healtherTemplateEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension String {
    var slugified: String {
        let allowed = CharacterSet.alphanumerics
        return lowercased()
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
            .reduce(into: "") { result, character in
                if character == "-", result.last == "-" {
                    return
                }
                result.append(character)
            }
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
