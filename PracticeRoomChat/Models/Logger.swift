import Foundation
import os.log

class Logger {
    static let shared = Logger()
    
    private let subsystem = "com.practiceroom.chat"
    private let categories = [
        "api": OSLog(subsystem: "com.practiceroom.chat", category: "API"),
        "ui": OSLog(subsystem: "com.practiceroom.chat", category: "UI"),
        "audio": OSLog(subsystem: "com.practiceroom.chat", category: "Audio"),
        "general": OSLog(subsystem: "com.practiceroom.chat", category: "General")
    ]
    
    private init() {}
    
    func api(_ message: String, type: OSLogType = .default) {
        os_log("%@", log: categories["api"]!, type: type, message)
        print("🌐 API: \(message)")
    }
    
    func ui(_ message: String, type: OSLogType = .default) {
        os_log("%@", log: categories["ui"]!, type: type, message)
        print("👆 UI: \(message)")
    }
    
    func audio(_ message: String, type: OSLogType = .default) {
        os_log("%@", log: categories["audio"]!, type: type, message)
        print("🎵 Audio: \(message)")
    }
    
    func info(_ message: String, type: OSLogType = .info) {
        os_log("%@", log: categories["general"]!, type: type, message)
        print("ℹ️ Info: \(message)")
    }
    
    func error(_ message: String, type: OSLogType = .error) {
        os_log("%@", log: categories["general"]!, type: type, message)
        print("❌ Error: \(message)")
    }
    
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        info("\(operation) took \(String(format: "%.2f", timeElapsed * 1000))ms")
        return result
    }
    
    // MARK: - Extraction-Specific Logging
    
    func extraction(_ message: String, type: OSLogType = .default) {
        os_log("%@", log: categories["general"]!, type: type, message)
        print("🎯 EXTRACTION: \(message)")
    }
    
    func parsing(_ message: String, type: OSLogType = .default) {
        os_log("%@", log: categories["general"]!, type: type, message)
        print("🧠 PARSING: \(message)")
    }
    
    func confidence(_ message: String, score: Double, type: OSLogType = .default) {
        os_log("%@", log: categories["general"]!, type: type, message)
        print("📊 CONFIDENCE (\(String(format: "%.2f", score))): \(message)")
    }
    
    func regex(_ pattern: String, matches: Int, type: OSLogType = .default) {
        os_log("Regex pattern matched %d times: %@", log: categories["general"]!, type: type, matches, pattern)
        print("🔍 REGEX: Pattern '\(pattern)' matched \(matches) times")
    }
    
    func concept(_ type: String, content: String, confidence: Double) {
        let message = "Type: \(type), Content: '\(content)', Confidence: \(String(format: "%.2f", confidence))"
        os_log("Musical concept extracted - %@", log: categories["general"]!, type: .info, message)
        print("🎵 CONCEPT: \(message)")
    }
}