import Foundation

// MARK: - Knowledge Base Data Models

struct MusicTheoryExample {
    let id: UUID
    let concept: String              // "major_chord", "minor_chord", etc.
    let title: String               // "Basic Major Chord Explanation"
    let content: String             // The actual explanation text
    let metadata: ExampleMetadata
    let musicalExamples: [MusicalExample]  // Audio examples to include
    let tags: [String]              // Searchable tags
    
    init(concept: String, title: String, content: String, metadata: ExampleMetadata, musicalExamples: [MusicalExample] = [], tags: [String] = []) {
        self.id = UUID()
        self.concept = concept
        self.title = title
        self.content = content
        self.metadata = metadata
        self.musicalExamples = musicalExamples
        self.tags = tags
    }
}

struct ExampleMetadata {
    let difficulty: DifficultyLevel
    let teachingStyle: TeachingStyle
    let musicalContext: MusicalContext
    let focus: ConceptualFocus
    let prerequisites: [String]     // Required prior knowledge
    let targetAudience: [String]    // "beginner", "classical_student", "jazz_student", etc.
    let estimatedReadTime: Int      // Seconds
}

enum DifficultyLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate" 
    case advanced = "advanced"
    case expert = "expert"
}

enum TeachingStyle: String, CaseIterable {
    case conceptual = "conceptual"      // Theory-heavy explanation
    case practical = "practical"        // Hands-on, application focused
    case visual = "visual"             // Uses diagrams, charts
    case auditory = "auditory"         // Heavy on audio examples
    case simple = "simple"             // Non-technical language
    case technical = "technical"       // Music theory terminology
    case comparison = "comparison"      // Side-by-side comparisons
}

enum MusicalContext: String, CaseIterable {
    case general = "general"           // Universal music theory
    case classical = "classical"       // Classical music context
    case jazz = "jazz"                // Jazz theory context
    case pop = "pop"                  // Popular music context
    case rock = "rock"                // Rock music context
    case folk = "folk"                // Folk music context
}

enum ConceptualFocus: String, CaseIterable {
    case definition = "definition"         // What is it?
    case construction = "construction"     // How to build it?
    case recognition = "recognition"       // How to identify it?
    case application = "application"       // How to use it?
    case theory = "theory"                // Why does it work?
    case comparison = "comparison"         // How does it relate to others?
    case history = "history"              // Historical context
    case analysis = "analysis"            // Breaking it down
}

// MARK: - Knowledge Base Manager

class MusicTheoryKnowledgeBase {
    static let shared = MusicTheoryKnowledgeBase()
    
    private var examples: [MusicTheoryExample] = []
    
    private init() {
        loadInitialExamples()
    }
    
    func searchExamples(
        for query: String,
        concept: String? = nil,
        difficulty: DifficultyLevel? = nil,
        style: TeachingStyle? = nil,
        context: MusicalContext? = nil,
        focus: ConceptualFocus? = nil,
        limit: Int = 10
    ) -> [MusicTheoryExample] {
        
        var filteredExamples = examples
        
        // Filter by concept
        if let concept = concept {
            filteredExamples = filteredExamples.filter { $0.concept == concept }
        }
        
        // Filter by metadata
        if let difficulty = difficulty {
            filteredExamples = filteredExamples.filter { $0.metadata.difficulty == difficulty }
        }
        
        if let style = style {
            filteredExamples = filteredExamples.filter { $0.metadata.teachingStyle == style }
        }
        
        if let context = context {
            filteredExamples = filteredExamples.filter { $0.metadata.musicalContext == context }
        }
        
        if let focus = focus {
            filteredExamples = filteredExamples.filter { $0.metadata.focus == focus }
        }
        
        // Semantic search by query (simplified for now - will enhance with embeddings later)
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        let scoredExamples = filteredExamples.map { example in
            let score = calculateRelevanceScore(example: example, queryWords: queryWords)
            return (example: example, score: score)
        }
        
        // Sort by relevance score and return top results
        return scoredExamples
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.example }
    }
    
    private func calculateRelevanceScore(example: MusicTheoryExample, queryWords: [String]) -> Double {
        var score = 0.0
        
        // Check title matches
        for word in queryWords {
            if example.title.lowercased().contains(word) {
                score += 2.0
            }
            if example.content.lowercased().contains(word) {
                score += 1.0
            }
            if example.tags.contains(where: { $0.lowercased().contains(word) }) {
                score += 1.5
            }
        }
        
        return score
    }
    
    func addExample(_ example: MusicTheoryExample) {
        examples.append(example)
    }
    
    func getAllExamplesFor(concept: String) -> [MusicTheoryExample] {
        return examples.filter { $0.concept == concept }
    }
    
    private func loadInitialExamples() {
        // Load our curated major chord examples
        examples = MajorChordExampleLibrary.getAllExamples()
    }
}

// MARK: - Search Query Analysis

struct QueryAnalysis {
    let detectedConcept: String?
    let inferredDifficulty: DifficultyLevel?
    let inferredStyle: TeachingStyle?
    let inferredFocus: ConceptualFocus?
    let keywords: [String]
}

class QueryAnalyzer {
    static func analyze(_ query: String) -> QueryAnalysis {
        let lowercased = query.lowercased()
        
        // Detect concept
        var concept: String? = nil
        if lowercased.contains("major chord") || lowercased.contains("major chords") {
            concept = "major_chord"
        }
        
        // Infer difficulty
        var difficulty: DifficultyLevel? = nil
        if lowercased.contains("simple") || lowercased.contains("basic") || lowercased.contains("beginner") {
            difficulty = .beginner
        } else if lowercased.contains("advanced") || lowercased.contains("complex") {
            difficulty = .advanced
        }
        
        // Infer teaching style
        var style: TeachingStyle? = nil
        if lowercased.contains("explain") || lowercased.contains("understand") {
            style = .conceptual
        } else if lowercased.contains("build") || lowercased.contains("make") || lowercased.contains("construct") {
            style = .practical
        } else if lowercased.contains("simple") || lowercased.contains("easy") {
            style = .simple
        }
        
        // Infer focus
        var focus: ConceptualFocus? = nil
        if lowercased.contains("what is") || lowercased.contains("define") {
            focus = .definition
        } else if lowercased.contains("how to") || lowercased.contains("build") {
            focus = .construction
        } else if lowercased.contains("sound") || lowercased.contains("hear") {
            focus = .recognition
        }
        
        let keywords = query.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
        
        return QueryAnalysis(
            detectedConcept: concept,
            inferredDifficulty: difficulty,
            inferredStyle: style,
            inferredFocus: focus,
            keywords: keywords
        )
    }
}