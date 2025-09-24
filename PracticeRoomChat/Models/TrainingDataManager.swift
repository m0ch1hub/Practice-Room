import Foundation

// MARK: - Data Models
struct TrainingExample: Codable {
    struct Content: Codable {
        let role: String
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String
    }

    struct Metadata: Codable {
        let display: String? // "main" shows in menu, "variation" is hidden
    }

    let metadata: Metadata?
    let contents: [Content]
}

/// Centralized manager for loading training data
/// Handles both development (direct file access) and production (bundle resource) scenarios
class TrainingDataManager {
    static let shared = TrainingDataManager()
    
    private init() {}
    
    /// Gets the URL for the training data file
    /// In development (simulator), tries to load from project directory first
    /// In production (device), loads from bundle resources
    func getTrainingDataURL() -> URL? {
        // Development path - when running in simulator, load directly from project
        #if targetEnvironment(simulator)
        // Try simple training data first
        let simpleProjectPath = "/Users/mochi/Documents/Practice Room Chat/PracticeRoomChat/Training Data/simple_training_data.jsonl"
        let simpleURL = URL(fileURLWithPath: simpleProjectPath)
        
        if FileManager.default.fileExists(atPath: simpleProjectPath) {
            // Loading from development path
            return simpleURL
        }
        
        // Fall back to original training data
        let projectPath = "/Users/mochi/Documents/Practice Room Chat/PracticeRoomChat/Training Data/training_data.jsonl"
        let developmentURL = URL(fileURLWithPath: projectPath)
        
        if FileManager.default.fileExists(atPath: projectPath) {
            // Loading from development path
            return developmentURL
        }
        #endif
        
        // Production path - load from bundle
        // Try simple_training_data first
        if let bundleURL = Bundle.main.url(forResource: "simple_training_data", withExtension: "jsonl") {
            // Loading from bundle
            return bundleURL
        }

        // Try with folder structure
        if let bundleURL = Bundle.main.url(forResource: "Training Data/simple_training_data", withExtension: "jsonl") {
            // Loading from bundle folder
            return bundleURL
        }

        // Fall back to original training_data
        if let bundleURL = Bundle.main.url(forResource: "training_data", withExtension: "jsonl") {
            // Loading from bundle root
            return bundleURL
        }
        
        // Training data file not found
        return nil
    }
    
    /// Loads training data as a string
    func loadTrainingDataString() throws -> String {
        guard let url = getTrainingDataURL() else {
            throw TrainingDataError.fileNotFound
        }
        
        return try String(contentsOf: url, encoding: .utf8)
    }
    
    /// Loads and parses training data into TrainingExample objects
    func loadTrainingExamples() -> [TrainingExample] {
        var examples: [TrainingExample] = []

        do {
            let dataString = try loadTrainingDataString()
            let lines = dataString.components(separatedBy: .newlines)

            for line in lines where !line.isEmpty {
                if let jsonData = line.data(using: .utf8),
                   let example = try? JSONDecoder().decode(TrainingExample.self, from: jsonData) {
                    examples.append(example)
                }
            }
        } catch {
            // Error loading training examples
        }

        return examples
    }

    /// Loads only main questions for display in menu (filters out variations)
    func loadMainQuestions() -> [TrainingExample] {
        return loadTrainingExamples().filter { example in
            // If no metadata or display is "main", show in menu
            // Backwards compatible: examples without metadata are considered "main"
            example.metadata?.display == "main" || example.metadata == nil
        }
    }
}

enum TrainingDataError: LocalizedError {
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Training data file not found. Please ensure training_data.jsonl is included in the project."
        }
    }
}