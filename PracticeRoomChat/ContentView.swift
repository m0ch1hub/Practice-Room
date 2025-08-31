//
//  ContentView.swift
//  Practice Room: Chat
//
//  Created by Aristotle Farrahi on 8/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingTestingMode = false
    
    var body: some View {
        NavigationView {
            ChatView()
                .navigationBarItems(trailing: Button(action: {
                    showingTestingMode = true
                }) {
                    Image(systemName: "testtube.2")
                        .font(.title2)
                        .foregroundColor(.blue)
                })
        }
        .sheet(isPresented: $showingTestingMode) {
            TestingModeView()
        }
    }
}

#Preview {
    ContentView()
}
