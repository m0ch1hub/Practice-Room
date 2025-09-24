import Foundation
import FirebaseFirestore
import UIKit

// MARK: - Feedback Models
struct FeedbackItem: Codable {
    let id: UUID
    let questionId: UUID
    let question: String
    let answer: String
    let rating: Rating
    let timestamp: Date
    let comments: String?

    enum Rating: String, Codable {
        case thumbsUp = "thumbsUp"
        case thumbsDown = "thumbsDown"
    }
}

struct GeneralFeedback: Codable {
    let id: String
    let type: FeedbackType
    let subject: String
    let message: String
    let email: String?
    let timestamp: Date
    let deviceId: String
    let appVersion: String
    let systemInfo: SystemInfo
    let status: FeedbackStatus

    enum FeedbackType: String, Codable, CaseIterable {
        case bug = "bug"
        case feature = "feature"
        case general = "general"
        case other = "other"

        var displayName: String {
            switch self {
            case .bug: return "Bug Report"
            case .feature: return "Feature Request"
            case .general: return "General Feedback"
            case .other: return "Other"
            }
        }
    }

    enum FeedbackStatus: String, Codable {
        case new = "new"
        case read = "read"
        case resolved = "resolved"
    }

    struct SystemInfo: Codable {
        let iosVersion: String
        let deviceModel: String
        let appBuild: String
    }
}

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()

    private let db = Firestore.firestore()
    @Published var feedbackItems: [FeedbackItem] = []
    @Published var messageRatings: [UUID: FeedbackItem.Rating] = [:]
    @Published var isSubmittingFeedback = false

    private let feedbackKey = "PracticeRoomFeedback"
    private let offlineQueueKey = "PracticeRoomOfflineFeedbackQueue"
    private let submissionCountKey = "PracticeRoomFeedbackSubmissionCount"

    private var deviceId: String {
        if let id = UserDefaults.standard.string(forKey: "PracticeRoomDeviceId") {
            return id
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "PracticeRoomDeviceId")
            return newId
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var totalSubmissions: Int {
        UserDefaults.standard.integer(forKey: submissionCountKey)
    }

    private init() {
        loadFeedback()
        processOfflineQueue()
    }

    // MARK: - Message Rating (Thumbs up/down)
    func rateMessage(messageId: UUID, question: String, answer: String, rating: FeedbackItem.Rating) {
        // Update local state immediately for instant UI feedback
        messageRatings[messageId] = rating

        // Create feedback item
        let feedback = FeedbackItem(
            id: UUID(),
            questionId: messageId,
            question: question,
            answer: String(answer.prefix(500)), // Limit answer length
            rating: rating,
            timestamp: Date(),
            comments: nil
        )

        // Update local storage
        feedbackItems.removeAll { $0.questionId == messageId }
        feedbackItems.append(feedback)
        saveFeedback()

        // Send to Firebase
        sendMessageRatingToFirebase(feedback)

        // Track submission count
        let currentCount = UserDefaults.standard.integer(forKey: submissionCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: submissionCountKey)

        Logger.shared.ui("Message rated: \(rating.rawValue)")

        // Track in analytics
        AnalyticsService.shared.track(event: .messageFeedback(rating: rating.rawValue))
    }

    private func sendMessageRatingToFirebase(_ feedback: FeedbackItem) {
        let data: [String: Any] = [
            "messageId": feedback.questionId.uuidString,
            "question": feedback.question,
            "answer": feedback.answer,
            "rating": feedback.rating.rawValue,
            "timestamp": Timestamp(date: feedback.timestamp),
            "deviceId": deviceId,
            "appVersion": appVersion
        ]

        db.collection("feedback_message_ratings").addDocument(data: data) { [weak self] error in
            if let error = error {
                Logger.shared.error("Failed to send rating to Firebase: \(error)")
                self?.queueForOfflineSync(data: data, collection: "message_ratings")
            } else {
                Logger.shared.ui("Rating sent to Firebase successfully")
            }
        }
    }

    // MARK: - General Feedback Submission
    func submitGeneralFeedback(type: GeneralFeedback.FeedbackType,
                              subject: String,
                              message: String,
                              email: String?,
                              completion: @escaping (Bool, String) -> Void) {

        isSubmittingFeedback = true

        let systemInfo = GeneralFeedback.SystemInfo(
            iosVersion: UIDevice.current.systemVersion,
            deviceModel: UIDevice.current.model,
            appBuild: appBuild
        )

        let feedback = GeneralFeedback(
            id: UUID().uuidString,
            type: type,
            subject: subject,
            message: message,
            email: email?.isEmpty == true ? nil : email,
            timestamp: Date(),
            deviceId: deviceId,
            appVersion: appVersion,
            systemInfo: systemInfo,
            status: .new
        )

        let data: [String: Any] = [
            "type": feedback.type.rawValue,
            "subject": feedback.subject,
            "message": feedback.message,
            "email": feedback.email ?? "",
            "timestamp": Timestamp(date: feedback.timestamp),
            "deviceId": feedback.deviceId,
            "appVersion": feedback.appVersion,
            "systemInfo": [
                "iosVersion": systemInfo.iosVersion,
                "deviceModel": systemInfo.deviceModel,
                "appBuild": systemInfo.appBuild
            ],
            "status": feedback.status.rawValue
        ]

        db.collection("feedback_general").addDocument(data: data) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSubmittingFeedback = false

                if let error = error {
                    Logger.shared.error("Failed to submit feedback: \(error)")
                    self?.queueForOfflineSync(data: data, collection: "general_feedback")
                    // Still report success to user as it will sync later
                    completion(true, "Feedback saved and will be sent when online")
                } else {
                    Logger.shared.ui("General feedback submitted successfully")
                    completion(true, "Thank you for your feedback!")
                }

                // Track in analytics
                AnalyticsService.shared.track(event: .generalFeedbackSubmitted(type: type.rawValue))
            }
        }
    }

    // MARK: - Offline Queue Management
    private func queueForOfflineSync(data: [String: Any], collection: String) {
        var queue = UserDefaults.standard.object(forKey: offlineQueueKey) as? [[String: Any]] ?? []
        var queueItem = data
        queueItem["_collection"] = collection
        queueItem["_queuedAt"] = Date().timeIntervalSince1970
        queue.append(queueItem)
        UserDefaults.standard.set(queue, forKey: offlineQueueKey)
    }

    private func processOfflineQueue() {
        guard let queue = UserDefaults.standard.object(forKey: offlineQueueKey) as? [[String: Any]],
              !queue.isEmpty else { return }

        var remainingQueue = queue

        for item in queue {
            guard let collection = item["_collection"] as? String else { continue }

            var data = item
            data.removeValue(forKey: "_collection")
            data.removeValue(forKey: "_queuedAt")

            let collectionName = collection == "message_ratings" ? "feedback_message_ratings" : "feedback_general"
            db.collection(collectionName).addDocument(data: data) { error in
                if error == nil {
                    remainingQueue.removeAll { dict in
                        (dict["_queuedAt"] as? TimeInterval) == (item["_queuedAt"] as? TimeInterval)
                    }
                    UserDefaults.standard.set(remainingQueue, forKey: self.offlineQueueKey)
                }
            }
        }
    }

    // MARK: - Legacy Support Methods
    func getRating(for messageId: UUID) -> FeedbackItem.Rating? {
        return messageRatings[messageId]
    }

    private func loadFeedback() {
        if let data = UserDefaults.standard.data(forKey: feedbackKey),
           let decoded = try? JSONDecoder().decode([FeedbackItem].self, from: data) {
            feedbackItems = decoded
            // Rebuild ratings dictionary
            for item in feedbackItems {
                messageRatings[item.questionId] = item.rating
            }
        }
    }

    private func saveFeedback() {
        if let encoded = try? JSONEncoder().encode(feedbackItems) {
            UserDefaults.standard.set(encoded, forKey: feedbackKey)
        }
    }

    func generateFeedbackReport() -> String {
        let thumbsUp = feedbackItems.filter { $0.rating == .thumbsUp }.count
        let thumbsDown = feedbackItems.filter { $0.rating == .thumbsDown }.count

        var report = "Practice Room Feedback Report\n"
        report += "Generated: \(Date().formatted())\n\n"
        report += "Total Ratings: \(feedbackItems.count)\n"
        report += "Thumbs Up: \(thumbsUp)\n"
        report += "Thumbs Down: \(thumbsDown)\n\n"

        if !feedbackItems.isEmpty {
            report += "Recent Feedback:\n"
            report += "================\n"
            for item in feedbackItems.suffix(10).reversed() {
                report += "\nQuestion: \(item.question)\n"
                report += "Rating: \(item.rating == .thumbsUp ? "👍" : "👎")\n"
                if let comments = item.comments, !comments.isEmpty {
                    report += "Comments: \(comments)\n"
                }
                report += "Time: \(item.timestamp.formatted())\n"
            }
        }

        return report
    }

    func clearAllFeedback() {
        feedbackItems.removeAll()
        messageRatings.removeAll()
        UserDefaults.standard.removeObject(forKey: feedbackKey)
    }
}