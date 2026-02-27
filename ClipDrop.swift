import SwiftUI
import UniformTypeIdentifiers

// MARK: - Theme

enum CDTheme {
    static let bg = Color(red: 0.11, green: 0.11, blue: 0.13)
    static let surface = Color(red: 0.16, green: 0.16, blue: 0.19)
    static let surfaceHover = Color(red: 0.20, green: 0.20, blue: 0.24)
    static let border = Color.white.opacity(0.08)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let accent = Color(red: 0.40, green: 0.65, blue: 1.0)
    static let success = Color(red: 0.30, green: 0.78, blue: 0.50)
    static let error = Color(red: 0.95, green: 0.35, blue: 0.35)
}

// MARK: - File Type

enum FileType: String, CaseIterable, Identifiable {
    case txt, md, swift, json, yaml, html, csv, log

    var id: String { rawValue }

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

    var ext: String {
        switch self {
        case .yaml: return "yml"
        default:    return rawValue
        }
    }

    var icon: String {
        switch self {
        case .txt:   return "doc.text"
        case .md:    return "doc.richtext"
        case .swift: return "swift"
        case .json:  return "curlybraces"
        case .yaml:  return "list.bullet.indent"
        case .html:  return "chevron.left.forwardslash.chevron.right"
        case .csv:   return "tablecells"
        case .log:   return "text.alignleft"
        }
    }

    var utType: UTType {
        switch self {
        case .txt:   return .plainText
        case .md:    return .init("net.daringfireball.markdown") ?? .plainText
        case .swift: return .swiftSource
        case .json:  return .json
        case .yaml:  return .yaml
        case .html:  return .html
        case .csv:   return .commaSeparatedText
        case .log:   return .log
        }
    }
}

// MARK: - Text Stats (pure functions for testing)

enum TextStats {
    static func charCount(_ s: String) -> Int {
        s.count
    }

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

    static func byteSize(_ s: String) -> Int {
        s.utf8.count
    }

    static func formattedSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Clipboard Manager

@Observable
final class ClipboardManager {
    var text: String = ""
    var fileType: FileType = .txt
    var statusMessage: String = ""
    var statusIsError: Bool = false
    var lastSaveDirectory: URL?

    private var statusGeneration: Int = 0

    func readClipboard() {
        if let content = NSPasteboard.general.string(forType: .string) {
            text = content
            showStatus("Clipboard loaded (\(TextStats.wordCount(content)) words)", isError: false)
        } else {
            showStatus("Clipboard is empty or contains non-text data", isError: true)
        }
    }

    func clearText() {
        text = ""
        showStatus("Cleared", isError: false)
    }

    func saveToFile() {
        let panel = NSSavePanel()
        panel.title = "Save As"
        panel.nameFieldStringValue = "clipboard.\(fileType.ext)"
        panel.allowedContentTypes = [fileType.utType]
        panel.canCreateDirectories = true

        if let dir = lastSaveDirectory {
            panel.directoryURL = dir
        }

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return
        }

        lastSaveDirectory = url.deletingLastPathComponent()

        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            let bytes = TextStats.byteSize(text)
            showStatus("Saved to \(url.lastPathComponent) (\(TextStats.formattedSize(bytes)))", isError: false)
        } catch {
            showStatus("Save failed: \(error.localizedDescription)", isError: true)
        }
    }

    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        showStatus("Copied to clipboard", isError: false)
    }

    private func showStatus(_ message: String, isError: Bool) {
        statusGeneration += 1
        let gen = statusGeneration
        statusMessage = message
        statusIsError = isError

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.statusGeneration == gen else { return }
            self.statusMessage = ""
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var manager = ClipboardManager()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CDTheme.accent)
                Text("ClipDrop")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CDTheme.textPrimary)
                Text("v0.1.0")
                    .font(.system(size: 10))
                    .foregroundStyle(CDTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().overlay(CDTheme.border)

            // Toolbar
            HStack(spacing: 8) {
                Button(action: { manager.readClipboard() }) {
                    Label("Paste", systemImage: "clipboard")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)

                Button(action: { manager.clearText() }) {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)

                Button(action: { manager.copyToClipboard() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)

                Spacer()

                Picker("", selection: $manager.fileType) {
                    ForEach(FileType.allCases) { ft in
                        Label(ft.label, systemImage: ft.icon).tag(ft)
                    }
                }
                .frame(width: 120)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider().overlay(CDTheme.border)

            // Text Editor
            TextEditor(text: $manager.text)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(CDTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(CDTheme.border)
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

            // Stats bar
            HStack(spacing: 16) {
                statItem("chars", value: TextStats.charCount(manager.text))
                statItem("words", value: TextStats.wordCount(manager.text))
                statItem("lines", value: TextStats.lineCount(manager.text))
                Text(TextStats.formattedSize(TextStats.byteSize(manager.text)))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(CDTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)

            // Status banner
            if !manager.statusMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: manager.statusIsError ? "exclamationmark.triangle" : "checkmark.circle")
                        .font(.system(size: 11))
                    Text(manager.statusMessage)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundStyle(manager.statusIsError ? CDTheme.error : CDTheme.success)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    (manager.statusIsError ? CDTheme.error : CDTheme.success).opacity(0.1)
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Divider().overlay(CDTheme.border)

            // Footer
            HStack {
                Button(action: { manager.saveToFile() }) {
                    Label("Save As\u{2026}", systemImage: "square.and.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.text.isEmpty)

                Spacer()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Quit")
                        .font(.system(size: 12))
                        .foregroundStyle(CDTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 380, height: 480)
        .background(CDTheme.bg)
        .colorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: manager.statusMessage)
        .onAppear {
            manager.readClipboard()
        }
    }

    private func statItem(_ label: String, value: Int) -> some View {
        HStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(CDTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(CDTheme.textSecondary)
        }
    }
}

// MARK: - App

@main
struct ClipDropApp: App {
    var body: some Scene {
        MenuBarExtra("ClipDrop", systemImage: "doc.on.clipboard") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
