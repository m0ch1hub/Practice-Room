import Foundation
import FirebaseAuth
import FirebaseFunctions

class FirebaseService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    
    private lazy var functions = Functions.functions()
    
    init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        self.user = result.user
        self.isAuthenticated = true
    }
    
    func callMusicTheoryAPI(message: String) async throws -> String {
        // Ensure user is authenticated
        if !isAuthenticated {
            try await signInAnonymously()
        }
        
        // Call Firebase Function
        let callable = functions.httpsCallable("musicTheoryChat")
        
        do {
            let result = try await callable.call(["message": message])
            
            if let data = result.data as? [String: Any],
               let response = data["response"] as? String {
                return response
            } else {
                throw APIError.invalidResponse
            }
        } catch {
            print("Firebase Function error: \(error)")
            throw APIError.requestFailed
        }
    }
}