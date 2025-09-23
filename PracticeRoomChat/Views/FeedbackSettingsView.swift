import SwiftUI
import MessageUI

struct FeedbackSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var feedbackText = ""
    @State private var showingCopyAlert = false
    @State private var showingClearAlert = false

    var body: some View {
        NavigationView {
            Form {
                // Feedback Statistics
                Section {
                    HStack {
                        Label("Helpful", systemImage: "hand.thumbsup.fill")
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(feedbackManager.feedbackItems.filter { $0.rating == .thumbsUp }.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Not Helpful", systemImage: "hand.thumbsdown.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Text("\(feedbackManager.feedbackItems.filter { $0.rating == .thumbsDown }.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Feedback Statistics")
                } footer: {
                    Text("Your ratings help us improve the app")
                        .font(.caption)
                }

                // Submit Feedback
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Share Your Thoughts")
                            .font(.headline)
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )

                        HStack {
                            Button(action: submitFeedback) {
                                Label("Copy Feedback", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(feedbackText.isEmpty)

                            Spacer()

                            if MFMailComposeViewController.canSendMail() {
                                Button(action: emailFeedback) {
                                    Label("Email", systemImage: "envelope")
                                }
                                .buttonStyle(.bordered)
                                .disabled(feedbackText.isEmpty)
                            }
                        }
                        .padding(.top, 4)
                    }
                } header: {
                    Text("Submit Feedback")
                } footer: {
                    Text("Tell us what you think about Practice Room")
                        .font(.caption)
                }

                // Clear Data
                Section {
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        HStack {
                            Label("Clear All Ratings", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                } footer: {
                    Text("This will delete all your feedback ratings")
                        .font(.caption)
                }

                // App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total Questions")
                        Spacer()
                        Text("\(TrainingDataManager.shared.loadMainQuestions().count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings & Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Feedback Copied", isPresented: $showingCopyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your feedback has been copied to the clipboard. You can paste it in an email or message.")
        }
        .alert("Clear All Ratings?", isPresented: $showingClearAlert) {
            Button("Clear", role: .destructive) {
                feedbackManager.clearAllFeedback()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your feedback ratings.")
        }
    }

    private func submitFeedback() {
        let fullFeedback = """
        Practice Room Feedback
        ======================
        User Comments:
        \(feedbackText)

        \(feedbackManager.generateFeedbackReport())
        """

        UIPasteboard.general.string = fullFeedback
        showingCopyAlert = true
        feedbackText = ""
    }

    private func emailFeedback() {
        let subject = "Practice Room Feedback"
        let body = """
        \(feedbackText)

        \(feedbackManager.generateFeedbackReport())
        """

        if let url = URL(string: "mailto:support@practiceroom.app?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    FeedbackSettingsView()
}