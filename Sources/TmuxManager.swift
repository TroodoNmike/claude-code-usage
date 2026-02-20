import Foundation

actor TmuxManager {
    private let sessionName: String

    init(sessionName: String = Config.tmuxSessionName) {
        self.sessionName = sessionName
    }

    // MARK: - Tmux availability

    static func findTmuxPath() -> String? {
        for path in ["/opt/homebrew/bin/tmux", "/usr/local/bin/tmux", "/usr/bin/tmux"] {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    // MARK: - Public API

    func sessionExists() async -> Bool {
        let (rc, _, _) = await runTmux("has-session", "-t", sessionName)
        return rc == 0
    }

    func createUsageSession() async {
        let (rc, _, _) = await runTmux(
            "new-session", "-d", "-s", sessionName,
            "-x", String(Config.tmuxPaneWidth),
            "-y", String(Config.tmuxPaneHeight)
        )
        guard rc == 0 else { return }
        await runTmux("send-keys", "-t", sessionName, "claude", "Enter")
        guard await waitForClaudeReady() else { return }
        await runTmux("send-keys", "-t", sessionName, "/usage")
        try? await Task.sleep(for: .milliseconds(500))
        await runTmux("send-keys", "-t", sessionName, "Enter")
    }

    func capturePane() async -> [String] {
        let (rc, stdout, _) = await runTmux("capture-pane", "-t", sessionName, "-p")
        guard rc == 0 else { return [] }
        return stdout.components(separatedBy: "\n")
    }

    func sendRefreshKeys() async {
        await runTmux("send-keys", "-t", sessionName, "Left")
        try? await Task.sleep(for: .milliseconds(Int(Config.usageKeyDelay * 1000)))
        await runTmux("send-keys", "-t", sessionName, "Right")
    }

    func killSession() async {
        await runTmux("kill-session", "-t", sessionName)
    }

    // MARK: - Private

    @discardableResult
    private func waitForClaudeReady(timeout: TimeInterval = 30, poll: TimeInterval = 1.0) async -> Bool {
        var elapsed: TimeInterval = 0
        while elapsed < timeout {
            let lines = await capturePane()
            let text = lines.joined(separator: " ")
            if text.contains("\u{273B}") || text.lowercased().contains("claude code") {
                return true
            }
            try? await Task.sleep(for: .milliseconds(Int(poll * 1000)))
            elapsed += poll
        }
        return false
    }

    @discardableResult
    private func runTmux(_ args: String...) async -> (Int32, String, String) {
        guard let tmuxPath = TmuxManager.findTmuxPath() else {
            return (-1, "", "tmux not found")
        }
        let argsCopy = Array(args)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: tmuxPath)
                process.arguments = argsCopy

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(returning: (
                        process.terminationStatus,
                        String(data: stdoutData, encoding: .utf8) ?? "",
                        String(data: stderrData, encoding: .utf8) ?? ""
                    ))
                } catch {
                    continuation.resume(returning: (-1, "", error.localizedDescription))
                }
            }
        }
    }
}
