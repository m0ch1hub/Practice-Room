//
//  ContentView.swift
//  Practice Room: Chat
//
//  Created by Aristotle Farrahi on 8/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showTestView = false
    
    var body: some View {
        NavigationView {
            if showTestView {
                TestMIDIView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Chat") {
                                showTestView = false
                            }
                        }
                    }
            } else {
                ChatView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Test MIDI") {
                                showTestView = true
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
