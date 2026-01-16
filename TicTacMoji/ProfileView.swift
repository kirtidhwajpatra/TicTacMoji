import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss
    
    let avatars = ["🍄", "🌼", "🤖", "👽", "🦄", "🐼", "🦊", "🦁"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Identify Yourself")) {
                    TextField("Name", text: $profileManager.currentUser.name)
                    Stepper("Age: \(profileManager.currentUser.age)", value: $profileManager.currentUser.age, in: 5...100)
                    
                    Picker("Gender", selection: $profileManager.currentUser.gender) {
                        ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }
                
                Section(header: Text("Choose Your Avatar")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                        ForEach(avatars, id: \.self) { avatar in
                            Text(avatar)
                                .font(.system(size: 40))
                                .padding(10)
                                .background(profileManager.currentUser.avatarRawValue == avatar ? Color.blue.opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    profileManager.updateAvatar(avatar)
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}
