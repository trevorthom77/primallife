import SwiftUI
import PhotosUI
import Supabase

struct ProfilePictureView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @Environment(\.supabaseClient) private var supabase
    @Environment(\.dismiss) private var dismiss
    @State private var profileImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showLocationPermission = false
    @State private var avatarURL: URL?
    
    private var isContinueEnabled: Bool {
        profileImage != nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Add your profile photo")
                        Text("📸")
                            .font(.custom(Fonts.semibold, size: 36))
                    }
                    .font(.onboardingTitle)
                    .foregroundColor(Colors.primaryText)
                    Text("Pick a clear photo of your face.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Colors.card)
                        .frame(height: 320)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            } else if let avatarURL {
                                AsyncImage(url: avatarURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                } placeholder: {
                                    placeholderContent
                                }
                            } else {
                                placeholderContent
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showLocationPermission = true
                } label: {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .disabled(!isContinueEnabled)
                .opacity(isContinueEnabled ? 1 : 0.6)
                
                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.goBackFont)
                        .foregroundColor(Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .onChange(of: selectedItem) { _, newValue in
            loadImage(from: newValue)
        }
        .onAppear {
            if profileImage == nil,
               let data = onboardingViewModel.profileImageData {
                profileImage = UIImage(data: data)
            }

            if let path = onboardingViewModel.avatarPath {
                avatarURL = makePublicAvatarURL(for: path)
            }
        }
        .navigationDestination(isPresented: $showLocationPermission) {
            LocationPermissionView()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            
            await MainActor.run {
                profileImage = uiImage
                onboardingViewModel.profileImageData = data
            }
            
            await uploadAvatar(data)
        }
    }
    
    private func uploadAvatar(_ data: Data) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        let path = "\(userID)/avatar.jpg"
        
        do {
            try await supabase.storage
                .from("profile-photos")
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))

            let publicURL = makePublicAvatarURL(for: path)
            
            await MainActor.run {
                onboardingViewModel.avatarPath = path
                avatarURL = publicURL
            }
        } catch {
            print("Avatar upload failed: \(error)")
        }
    }
    
    private func makePublicAvatarURL(for path: String) -> URL? {
        guard let supabase else { return nil }

        do {
            return try supabase.storage
                .from("profile-photos")
                .getPublicURL(path: path)
        } catch {
            print("Failed to create public URL: \(error)")
            return nil
        }
    }
    
    private var placeholderContent: some View {
        VStack(spacing: 8) {
            Text("Tap to upload your photo")
                .font(.travelDetail)
                .foregroundColor(Colors.primaryText)
            Text("Make sure your face is easy to see.")
                .font(.travelBody)
                .foregroundColor(Colors.secondaryText)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://fefucqrztvepcbfjikrq.supabase.co")!,
        supabaseKey: "sb_publishable_2AWQG4a-U37T-pgp5FYnJA_28ymb116"
    )
    
    return ProfilePictureView()
        .environment(\.supabaseClient, supabase)
        .environmentObject(OnboardingViewModel())
}
