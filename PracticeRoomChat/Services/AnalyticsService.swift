import Foundation
import FirebaseFirestore
import FirebaseAuth

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    private let db = Firestore.firestore()
    let sessionId: String

    private init() {
        // Create anonymous session ID (resets each app launch)
        self.sessionId = UUID().uuidString

        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
    }

    // MARK: - Track Interactions
    func trackInteraction(userInput: String, appResponse: String, responseTime: Double? = nil, error: Error? = nil) {
        // Privacy: Only collect what we need to improve
        let data: [String: Any] = [
            "sessionId": sessionId,
            "timestamp": FieldValue.serverTimestamp(),
            "userInput": userInput.prefix(200).description, // Limit length
            "appResponsePreview": String(appResponse.prefix(200)), // First 200 chars
            "hasAudioExamples": appResponse.contains("[MIDI:"),
            "responseLength": appResponse.count,
            "responseTime": responseTime ?? 0,
            "errorOccurred": error != nil,
            "errorMessage": error?.localizedDescription ?? "",
            "deviceModel": getDeviceModel(),
            "appVersion": getAppVersion(),
            "iosVersion": UIDevice.current.systemVersion
        ]

        // Fire and forget - don't block UI
        db.collection("interactions")
            .addDocument(data: data) { error in
                if let error = error {
                    Logger.shared.error("Analytics failed: \(error)")
                    // Store locally if Firebase fails
                    self.storeLocally(data)
                }
            }
    }

    // MARK: - Track Errors
    func trackError(error: String, context: String) {
        let data: [String: Any] = [
            "sessionId": sessionId,
            "timestamp": FieldValue.serverTimestamp(),
            "error": error,
            "context": context,
            "deviceModel": getDeviceModel(),
            "appVersion": getAppVersion()
        ]

        db.collection("errors").addDocument(data: data)
    }

    // MARK: - Track Feature Usage
    func trackFeature(feature: String, properties: [String: Any] = [:]) {
        var data: [String: Any] = [
            "sessionId": sessionId,
            "timestamp": FieldValue.serverTimestamp(),
            "feature": feature,
            "deviceModel": getDeviceModel(),
            "appVersion": getAppVersion()
        ]

        // Add any custom properties
        for (key, value) in properties {
            data[key] = value
        }

        db.collection("features").addDocument(data: data)
    }

    // MARK: - Track Events
    enum Event {
        case messageFeedback(rating: String)
        case generalFeedbackSubmitted(type: String)
    }

    func track(event: Event) {
        switch event {
        case .messageFeedback(let rating):
            trackFeature(feature: "message_feedback", properties: ["rating": rating])
        case .generalFeedbackSubmitted(let type):
            trackFeature(feature: "general_feedback", properties: ["type": type])
        }
    }

    // MARK: - Get Analytics Summary (for you to view)
    func getRecentInteractions(limit: Int = 100) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("interactions")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.map { $0.data() }
    }

    func getMostCommonQuestions(days: Int = 7) async throws -> [(String, Int)] {
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))

        let snapshot = try await db.collection("interactions")
            .whereField("timestamp", isGreaterThan: Timestamp(date: cutoffDate))
            .getDocuments()

        // Count question frequency
        var questionCounts: [String: Int] = [:]
        for doc in snapshot.documents {
            if let question = doc.data()["userInput"] as? String {
                let cleanQuestion = question.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                questionCounts[cleanQuestion, default: 0] += 1
            }
        }

        // Sort by frequency
        return questionCounts.sorted { $0.value > $1.value }
            .prefix(20)
            .map { ($0.key, $0.value) }
    }

    // MARK: - Local Storage Fallback
    private func storeLocally(_ data: [String: Any]) {
        var stored = UserDefaults.standard.object(forKey: "pending_analytics") as? [[String: Any]] ?? []
        stored.append(data)

        // Keep only last 100 events locally
        if stored.count > 100 {
            stored = Array(stored.suffix(100))
        }

        UserDefaults.standard.set(stored, forKey: "pending_analytics")
    }

    func uploadPendingAnalytics() {
        guard let pending = UserDefaults.standard.object(forKey: "pending_analytics") as? [[String: Any]] else { return }

        for data in pending {
            db.collection("interactions").addDocument(data: data)
        }

        // Clear after uploading
        UserDefaults.standard.removeObject(forKey: "pending_analytics")
    }

    // MARK: - Helpers
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? UIDevice.current.model
    }

    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Privacy Compliance
extension AnalyticsService {
    var isTrackingEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "analytics_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "analytics_enabled") }
    }

    func requestTrackingPermission(completion: @escaping (Bool) -> Void) {
        // Show alert to user
        // For now, just enable by default
        isTrackingEnabled = true
        completion(true)
    }
}