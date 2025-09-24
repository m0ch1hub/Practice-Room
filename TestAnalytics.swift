// Quick test to verify analytics is working
// Run this in Xcode playground or add to app temporarily

import Foundation

// Check if analytics data is being stored locally
let pending = UserDefaults.standard.object(forKey: "pending_analytics") as? [[String: Any]] ?? []
print("Pending analytics events: \(pending.count)")

for event in pending {
    if let input = event["userInput"] as? String {
        print("User asked: \(input)")
    }
    if let response = event["appResponsePreview"] as? String {
        print("App replied: \(response.prefix(50))...")
    }
}

// Check feedback count
let feedbackCount = UserDefaults.standard.integer(forKey: "PracticeRoomFeedbackSubmissionCount")
print("\nTotal feedback submissions: \(feedbackCount)")

// Check if we have a session ID
if let sessionId = event["sessionId"] as? String {
    print("Session ID: \(sessionId)")
}