import SwiftUI

struct FeedbackSubmissionView: View {
    let messageId: UUID
    let question: String
    let answer: String
    let initialRating: FeedbackItem.Rating
    @Binding var isPresented: Bool

    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var feedbackText = ""
    @State private var showingThankYouAlert = false

    var body: some View {
        NavigationView {
            Form {
                // Rating Section
                Section {
                    HStack {
                        Text("Your Rating")
                        Spacer()
                        Image(systemName: initialRating == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                            .foregroundColor(initialRating == .thumbsUp ? .green : .red)
                            .font(.title2)
                    }
                } header: {
                    Text("Feedback")
                }

                // Question & Answer Context
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(question)
                            .font(.system(size: 15))

                        Divider()

                        Text("Answer:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(answer)
                            .font(.system(size: 15))
                            .lineLimit(5)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Context")
                }

                // Additional Comments
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tell us more (optional)")
                            .font(.headline)
                        Text(initialRating == .thumbsUp ?
                             "What did you find helpful?" :
                             "How can we improve this answer?")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                } header: {
                    Text("Additional Feedback")
                }

                // Submit Button
                Section {
                    Button(action: submitFeedback) {
                        HStack {
                            Spacer()
                            Text("Submit Feedback")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Submit Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .alert("Thank You!", isPresented: $showingThankYouAlert) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("Your feedback helps us improve Practice Room.")
        }
    }

    private func submitFeedback() {
        // Save the rating and any additional comments
        feedbackManager.rateFeedbackWithComments(
            for: messageId,
            question: question,
            answer: answer,
            rating: initialRating,
            comments: feedbackText
        )

        // Send via email (works on real device)
        let subject = "Practice Room Feedback: \(initialRating == .thumbsUp ? "👍" : "👎")"
        let body = """
        Rating: \(initialRating == .thumbsUp ? "Helpful" : "Not Helpful")

        Question: \(question)

        Answer: \(answer)

        User Comments: \(feedbackText.isEmpty ? "None" : feedbackText)

        Time: \(Date().formatted())
        """

        // Create mailto URL - this opens Mail app on real device
        if let url = URL(string: "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }

        // Show thank you and dismiss
        showingThankYouAlert = true
    }
}

#Preview {
    FeedbackSubmissionView(
        messageId: UUID(),
        question: "What is a major chord?",
        answer: "A major chord consists of three notes...",
        initialRating: .thumbsUp,
        isPresented: .constant(true)
    )
}