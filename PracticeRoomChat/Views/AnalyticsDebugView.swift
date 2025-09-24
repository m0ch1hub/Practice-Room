import SwiftUI

struct AnalyticsDebugView: View {
    @StateObject private var analytics = AnalyticsService.shared
    @State private var recentInteractions: [[String: Any]] = []
    @State private var commonQuestions: [(String, Int)] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                // Summary Section
                Section("Analytics Summary") {
                    HStack {
                        Text("Session ID")
                        Spacer()
                        Text(String(analytics.sessionId.prefix(8)) + "...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Tracking Enabled")
                        Spacer()
                        Toggle("", isOn: .constant(analytics.isTrackingEnabled))
                            .disabled(true)
                    }
                }

                // Most Common Questions
                Section("Top Questions (Last 7 Days)") {
                    if commonQuestions.isEmpty {
                        Text("No data yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(commonQuestions.prefix(10), id: \.0) { question, count in
                            HStack {
                                Text(question)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(count)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Recent Interactions
                Section("Recent Interactions") {
                    if recentInteractions.isEmpty {
                        Text("No interactions yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(recentInteractions.enumerated()), id: \.offset) { index, interaction in
                            VStack(alignment: .leading, spacing: 4) {
                                // User Input
                                Text("Q: \(interaction["userInput"] as? String ?? "N/A")")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .lineLimit(2)

                                // Response Preview
                                if let response = interaction["appResponsePreview"] as? String {
                                    Text("A: \(response)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }

                                // Metadata
                                HStack {
                                    if let hasAudio = interaction["hasAudioExamples"] as? Bool, hasAudio {
                                        Label("Audio", systemImage: "music.note")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }

                                    if let responseTime = interaction["responseTime"] as? Double {
                                        Text("\(String(format: "%.1fs", responseTime))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    if let error = interaction["errorOccurred"] as? Bool, error {
                                        Label("Error", systemImage: "exclamationmark.triangle")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Export Section
                Section {
                    Button(action: exportData) {
                        Label("Export Analytics Data", systemImage: "square.and.arrow.up")
                    }

                    Button(action: clearLocalData) {
                        Label("Clear Local Cache", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Analytics Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        Task {
            isLoading = true
            do {
                // Get recent interactions
                recentInteractions = try await analytics.getRecentInteractions(limit: 50)

                // Get common questions
                commonQuestions = try await analytics.getMostCommonQuestions(days: 7)
            } catch {
                Logger.shared.error("Failed to load analytics: \(error)")
            }
            isLoading = false
        }
    }

    private func exportData() {
        var exportText = "Practice Room Analytics Export\n"
        exportText += "Generated: \(Date().formatted())\n\n"

        exportText += "TOP QUESTIONS:\n"
        for (question, count) in commonQuestions {
            exportText += "\(count)x - \(question)\n"
        }

        exportText += "\nRECENT INTERACTIONS:\n"
        for interaction in recentInteractions {
            if let q = interaction["userInput"] as? String,
               let a = interaction["appResponsePreview"] as? String {
                exportText += "\nQ: \(q)\nA: \(a)\n"
            }
        }

        UIPasteboard.general.string = exportText

        // Show alert that it's copied
        // (In production, you'd show an alert here)
    }

    private func clearLocalData() {
        UserDefaults.standard.removeObject(forKey: "pending_analytics")
        recentInteractions = []
        commonQuestions = []
    }
}

#Preview {
    AnalyticsDebugView()
}