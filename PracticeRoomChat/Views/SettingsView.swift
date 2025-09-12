import SwiftUI

struct SettingsView: View {
    @AppStorage("useLocalTrainingData") private var useLocalTrainingData = false
    @Environment(\.dismiss) private var dismiss
    
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
}

#Preview {
    SettingsView()
}