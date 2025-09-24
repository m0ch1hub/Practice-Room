import Foundation

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

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()

    @Published var feedbackItems: [FeedbackItem] = []
    @Published var messageRatings: [UUID: FeedbackItem.Rating] = [:]

    private let feedbackKey = "PracticeRoomFeedback"
    private let submissionCountKey = "PracticeRoomFeedbackSubmissionCount"

    var totalSubmissions: Int {
        UserDefaults.standard.integer(forKey: submissionCountKey)
    }

    private init() {
        loadFeedback()
    }

    func rateFeedback(for messageId: UUID, question: String, answer: String, rating: FeedbackItem.Rating) {
        rateFeedbackWithComments(for: messageId, question: question, answer: answer, rating: rating, comments: nil)
    }

    func rateFeedbackWithComments(for messageId: UUID, question: String, answer: String, rating: FeedbackItem.Rating, comments: String?) {
        // Update or add rating
        messageRatings[messageId] = rating

        // Create feedback item
        let feedback = FeedbackItem(
            id: UUID(),
            questionId: messageId,
            question: question,
            answer: answer,
            rating: rating,
            timestamp: Date(),
            comments: comments?.isEmpty == true ? nil : comments
        )

        // Remove any existing feedback for this message
        feedbackItems.removeAll { $0.questionId == messageId }

        // Add new feedback
        feedbackItems.append(feedback)

        // Save to UserDefaults
        saveFeedback()

        // Track submission count
        let currentCount = UserDefaults.standard.integer(forKey: submissionCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: submissionCountKey)

        Logger.shared.ui("Feedback recorded: \(rating.rawValue) for message \(messageId) (Total: \(currentCount + 1))")
    }

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