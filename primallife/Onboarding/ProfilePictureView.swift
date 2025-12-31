import SwiftUI
import Supabase
import UIKit

struct ProfilePictureView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @Environment(\.supabaseClient) private var supabase
    @Environment(\.dismiss) private var dismiss
    @State private var profileImage: UIImage?
    @State private var isShowingPhotoPicker = false
    @State private var showLocationPermission = false
    @State private var avatarURL: URL?
    @State private var isUploading = false
    
    private var isContinueEnabled: Bool {
        onboardingViewModel.avatarPath != nil
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
                
                Button {
                    isShowingPhotoPicker = true
                } label: {
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
                .buttonStyle(.plain)
                .sheet(isPresented: $isShowingPhotoPicker) {
                    CroppingImagePicker { image, data in
                        profileImage = image
                        onboardingViewModel.profileImageData = data
                        Task {
                            await uploadAvatar(data)
                        }
                    }
                    .ignoresSafeArea()
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showLocationPermission = true
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.travelDetail)
                            .foregroundColor(Colors.tertiaryText)
                        
                        if isUploading {
                            ProgressView()
                                .tint(Colors.tertiaryText)
                        }
                    }
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
    
    private func uploadAvatar(_ data: Data) async {
        await MainActor.run {
            isUploading = true
        }

        defer {
            Task {
                await MainActor.run {
                    isUploading = false
                }
            }
        }

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

private struct CroppingImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage, Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CroppingImagePicker

        init(parent: CroppingImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            guard let selectedImage,
                  let data = selectedImage.jpegData(compressionQuality: 0.9) else {
                parent.dismiss()
                return
            }

            parent.onImagePicked(selectedImage, data)
            parent.dismiss()
        }
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
