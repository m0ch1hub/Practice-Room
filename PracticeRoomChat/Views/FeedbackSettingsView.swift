import SwiftUI

struct FeedbackSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var showingGeneralFeedback = false
    @State private var showingClearAlert = false

    var body: some View {
        NavigationView {
            Form {
                // Submit Feedback Button
                Section {
                    Button(action: {
                        showingGeneralFeedback = true
                    }) {
                        HStack {
                            Label("Submit Feedback", systemImage: "envelope.fill")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingGeneralFeedback) {
            GeneralFeedbackView()
        }
    }
}

#Preview {
    FeedbackSettingsView()
}