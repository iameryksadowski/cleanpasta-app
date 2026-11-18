import Foundation

/// File operations for the command line tool link. Paths are explicit so
/// failures can be tested without changing the user's command line installation.
public enum CLIInstallation {
    public static func install(helper: URL, folder: URL) throws {
        let fm = FileManager.default
        guard fm.isExecutableFile(atPath: helper.path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let link = folder.appendingPathComponent("cleanpasta")
        if let destination = try? fm.destinationOfSymbolicLink(atPath: link.path) {
            if destination == helper.path { return }
            guard isOurs(destination: destination, folder: folder) else {
                throw CocoaError(.fileWriteFileExists)
            }
            // Create first, then replace atomically, so a failed install keeps the old link.
            let temporary = folder.appendingPathComponent(".cleanpasta-" + UUID().uuidString)
            defer { try? fm.removeItem(at: temporary) }
            try fm.createSymbolicLink(at: temporary, withDestinationURL: helper)
            guard rename(temporary.path, link.path) == 0 else {
                throw CocoaError(.fileWriteUnknown)
            }
        } else {
            // Creating a symlink fails if a regular file already exists. Never delete it.
            try fm.createSymbolicLink(at: link, withDestinationURL: helper)
        }
    }
    /// True when a link destination points into a Cleanpasta bundle, so the link is ours to replace.
    public static func isOurs(destination: String, folder: URL) -> Bool {
        let target = URL(fileURLWithPath: destination, relativeTo: folder).standardizedFileURL
        let parts = target.pathComponents
        return parts.count >= 4
            && parts[parts.count - 4] == "Cleanpasta.app"
            && Array(parts.suffix(3)) == ["Contents", "Helpers", "cleanpasta"]
    }

    /// Since 1.2.0 the command lives in ~/.local/bin, like the other apps by Eryk Sadowski.
    /// Links that 1.1.x and earlier put into /opt/homebrew/bin or /usr/local/bin move there:
    /// the new link is created first, and the old ones are removed only when a new Terminal
    /// finds ~/.local/bin (`removeOld`), so the command never disappears.
    /// Returns the old links that are still in place.
    @discardableResult
    public static func moveToLocalBin(previousFolders: [URL], helper: URL, localBin: URL, removeOld: Bool) throws -> [URL] {
        let fm = FileManager.default
        let old = previousFolders.map { $0.appendingPathComponent("cleanpasta") }.filter { link in
            guard let destination = try? fm.destinationOfSymbolicLink(atPath: link.path) else { return false }
            return isOurs(destination: destination, folder: link.deletingLastPathComponent())
        }
        guard !old.isEmpty else { return [] }
        try install(helper: helper, folder: localBin)
        guard removeOld else { return old }
        for link in old { try fm.removeItem(at: link) }
        return []
    }

    /// Whether a new Terminal finds `folder`. An app does not get the shell's PATH, so this reads
    /// the files the shell reads instead of running the user's startup scripts.
    public static func isOnShellPath(_ folder: URL, home: URL, environmentPath: String) -> Bool {
        if environmentPath.split(separator: ":").contains(Substring(folder.path)) { return true }
        let relative = folder.path.hasPrefix(home.path + "/") ? String(folder.path.dropFirst(home.path.count + 1)) : folder.path
        let shellFiles = [".zshenv", ".zprofile", ".zshrc", ".bash_profile", ".bashrc", ".profile", ".config/fish/config.fish"]
        for name in shellFiles {
            guard let text = try? String(contentsOf: home.appendingPathComponent(name), encoding: .utf8) else { continue }
            for line in text.split(separator: "\n") where !line.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                if (line.contains("PATH") || line.contains("fish_add_path")) && line.contains(relative) { return true }
            }
        }
        return false
    }

}
