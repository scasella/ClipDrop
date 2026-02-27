import Foundation

// MARK: - Test Harness

var passed = 0
var failed = 0

func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
    if condition {
        passed += 1
        print("  \u{2713} \(message)")
    } else {
        failed += 1
        print("  \u{2717} FAIL: \(message) (\(file):\(line))")
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String, file: String = #file, line: Int = #line) {
    if a == b {
        passed += 1
        print("  \u{2713} \(message)")
    } else {
        failed += 1
        print("  \u{2717} FAIL: \(message) — got '\(a)', expected '\(b)' (\(file):\(line))")
    }
}

// MARK: - TextStats (copied from ClipDrop.swift for standalone testing)

enum TextStats {
    static func charCount(_ s: String) -> Int { s.count }

    static func wordCount(_ s: String) -> Int {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return trimmed.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    static func lineCount(_ s: String) -> Int {
        if s.isEmpty { return 0 }
        return s.components(separatedBy: .newlines).count
    }

    static func byteSize(_ s: String) -> Int { s.utf8.count }

    static func formattedSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - FileType Extension Tests

enum FileType: String, CaseIterable {
    case txt, md, swift, json, yaml, html, csv, log

    var ext: String {
        switch self {
        case .yaml: return "yml"
        default:    return rawValue
        }
    }

    var label: String {
        switch self {
        case .txt:   return "Plain Text"
        case .md:    return "Markdown"
        case .swift: return "Swift"
        case .json:  return "JSON"
        case .yaml:  return "YAML"
        case .html:  return "HTML"
        case .csv:   return "CSV"
        case .log:   return "Log"
        }
    }
}

// MARK: - Tests

print("=== ClipDrop Tests ===\n")

// TextStats.charCount
print("charCount:")
assertEqual(TextStats.charCount(""), 0, "empty string")
assertEqual(TextStats.charCount("hello"), 5, "simple word")
assertEqual(TextStats.charCount("hello world"), 11, "two words with space")
assertEqual(TextStats.charCount("a\nb\nc"), 5, "with newlines (counts newlines)")

// TextStats.wordCount
print("\nwordCount:")
assertEqual(TextStats.wordCount(""), 0, "empty string")
assertEqual(TextStats.wordCount("   "), 0, "whitespace only")
assertEqual(TextStats.wordCount("hello"), 1, "single word")
assertEqual(TextStats.wordCount("hello world"), 2, "two words")
assertEqual(TextStats.wordCount("  hello   world  "), 2, "extra spaces")
assertEqual(TextStats.wordCount("one\ntwo\nthree"), 3, "newline-separated")
assertEqual(TextStats.wordCount("hello\n\n\nworld"), 2, "multiple newlines")
assertEqual(TextStats.wordCount("a b c d e"), 5, "five words")

// TextStats.lineCount
print("\nlineCount:")
assertEqual(TextStats.lineCount(""), 0, "empty string")
assertEqual(TextStats.lineCount("hello"), 1, "single line")
assertEqual(TextStats.lineCount("a\nb"), 2, "two lines")
assertEqual(TextStats.lineCount("a\nb\nc"), 3, "three lines")
assertEqual(TextStats.lineCount("\n"), 2, "just a newline = 2 lines")
assertEqual(TextStats.lineCount("a\n"), 2, "trailing newline")

// TextStats.byteSize
print("\nbyteSize:")
assertEqual(TextStats.byteSize(""), 0, "empty string")
assertEqual(TextStats.byteSize("hello"), 5, "ASCII")
assertEqual(TextStats.byteSize("caf\u{00E9}"), 5, "UTF-8 multi-byte (cafe with accent)")

// TextStats.formattedSize
print("\nformattedSize:")
assertEqual(TextStats.formattedSize(0), "0 B", "zero bytes")
assertEqual(TextStats.formattedSize(512), "512 B", "bytes")
assertEqual(TextStats.formattedSize(1024), "1.0 KB", "exactly 1 KB")
assertEqual(TextStats.formattedSize(1536), "1.5 KB", "1.5 KB")
assertEqual(TextStats.formattedSize(1048576), "1.0 MB", "exactly 1 MB")

// FileType extensions
print("\nFileType.ext:")
assertEqual(FileType.txt.ext, "txt", "txt extension")
assertEqual(FileType.md.ext, "md", "md extension")
assertEqual(FileType.swift.ext, "swift", "swift extension")
assertEqual(FileType.json.ext, "json", "json extension")
assertEqual(FileType.yaml.ext, "yml", "yaml -> yml")
assertEqual(FileType.html.ext, "html", "html extension")
assertEqual(FileType.csv.ext, "csv", "csv extension")
assertEqual(FileType.log.ext, "log", "log extension")

// FileType labels
print("\nFileType.label:")
assertEqual(FileType.txt.label, "Plain Text", "txt label")
assertEqual(FileType.md.label, "Markdown", "md label")
assertEqual(FileType.yaml.label, "YAML", "yaml label")

// FileType allCases count
print("\nFileType:")
assertEqual(FileType.allCases.count, 8, "8 file types")

// Summary
print("\n=== Results: \(passed) passed, \(failed) failed ===")
if failed > 0 {
    exit(1)
}
