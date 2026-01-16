import SwiftUI
import Combine

struct UserProfile: Codable, Equatable {
    var name: String
    var age: Int
    var avatarRawValue: String // Store the emoji char or system image name
    var gender: Gender
    
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case nonBinary = "Non-Binary"
    }
    
    static let defaultProfile = UserProfile(name: "Player", age: 10, avatarRawValue: "🍄", gender: .nonBinary)
}

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @AppStorage("user_profile_data") private var profileData: Data = Data()
    
    @Published var currentUser: UserProfile {
        didSet {
            saveProfile()
        }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "user_profile_data"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = decoded
        } else {
            self.currentUser = .defaultProfile
        }
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            profileData = encoded
        }
    }
    
    func updateName(_ name: String) {
        currentUser.name = name
    }
    
    func updateAvatar(_ avatar: String) {
        currentUser.avatarRawValue = avatar
    }
}
