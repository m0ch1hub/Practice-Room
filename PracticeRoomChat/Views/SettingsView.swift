import SwiftUI

struct SettingsView: View {
    @AppStorage("useLocalTrainingData") private var useLocalTrainingData = false
    @AppStorage("selectedSoundFont") private var selectedSoundFont = SoundEngine.SoundFont.yamaha.rawValue
    @AppStorage("notationDisplay") private var notationDisplay = NotationDisplay.keyboard.rawValue
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundEngine = SoundEngine.shared

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(isOn: $useLocalTrainingData) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use Local Training Data")
                                .font(.headline)
                            Text("Use local JSONL file instead of AI model")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Data Source")
                } footer: {
                    Text(useLocalTrainingData ? 
                         "Using local training examples from simple_training_data.jsonl" : 
                         "Using fine-tuned Vertex AI model")
                        .font(.caption)
                }
                
                Section {
                    Picker("Sound", selection: $selectedSoundFont) {
                        ForEach(SoundEngine.SoundFont.allCases, id: \.rawValue) { soundFont in
                            Text(soundFont.rawValue).tag(soundFont.rawValue)
                        }
                    }
                    .onChange(of: selectedSoundFont) { newValue in
                        if let soundFont = SoundEngine.SoundFont.allCases.first(where: { $0.rawValue == newValue }) {
                            soundEngine.switchSoundFont(to: soundFont)
                        }
                    }
                } header: {
                    Text("Audio")
                } footer: {
                    Text(selectedSoundFont == SoundEngine.SoundFont.yamaha.rawValue ?
                         "Classic grand piano sound" :
                         "Vintage electric piano sound")
                        .font(.caption)
                }

                Section {
                    Picker("Display", selection: $notationDisplay) {
                        ForEach(NotationDisplay.allCases, id: \.rawValue) { display in
                            Text(display.displayName).tag(display.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Notation Display")
                } footer: {
                    Text(getNotationDisplayDescription())
                        .font(.caption)
                }

                Section {
                    HStack {
                        Text("Model Endpoint")
                        Spacer()
                        Text("1255355306385342464")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Project ID")
                        Spacer()
                        Text("gen-lang-client-0477203387")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("AI Configuration")
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
    }

    private func getNotationDisplayDescription() -> String {
        switch NotationDisplay(rawValue: notationDisplay) ?? .keyboard {
        case .keyboard:
            return "Traditional piano keyboard view"
        case .staff:
            return "Musical staff notation with notes"
        case .both:
            return "Split view showing both keyboard and staff"
        }
    }
}

// MARK: - Notation Display Mode
enum NotationDisplay: String, CaseIterable {
    case keyboard = "keyboard"
    case staff = "staff"
    case both = "both"

    var displayName: String {
        switch self {
        case .keyboard: return "Piano"
        case .staff: return "Staff"
        case .both: return "Both"
        }
    }
}

#Preview {
    SettingsView()
}