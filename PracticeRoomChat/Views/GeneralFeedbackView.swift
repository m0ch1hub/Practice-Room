import SwiftUI

struct GeneralFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager.shared

    @State private var feedbackType = GeneralFeedback.FeedbackType.general
    @State private var subject = ""
    @State private var message = ""
    @State private var email = ""
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Subject
                Section {
                    TextField("Subject", text: $subject)
                } header: {
                    Text("Subject")
                }

                // Message
                Section {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                } header: {
                    Text("Your Feedback")
                }

                // Email (Optional)
                Section {
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } header: {
                    Text("Email (Optional)")
                } footer: {
                    Text("Include your email if you'd like us to respond")
                        .font(.caption)
                }

                // Submit Button
                Section {
                    Button(action: submitFeedback) {
                        if feedbackManager.isSubmittingFeedback {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Sending...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Submit Feedback")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                        }
                    }
                    .disabled(!isFormValid || feedbackManager.isSubmittingFeedback)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Submit Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Feedback Sent!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }

    private var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitFeedback() {
        // Trim whitespace
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        feedbackManager.submitGeneralFeedback(
            type: feedbackType,
            subject: trimmedSubject,
            message: trimmedMessage,
            email: trimmedEmail.isEmpty ? nil : trimmedEmail
        ) { success, message in
            if success {
                successMessage = message
                showingSuccessAlert = true
            } else {
                // Handle error (though we're always returning success for offline queue)
                successMessage = message
                showingSuccessAlert = true
            }
        }
    }
}

#Preview {
    GeneralFeedbackView()
}