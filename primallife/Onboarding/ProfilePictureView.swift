import SwiftUI
import PhotosUI

struct ProfilePictureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profileImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showLocationPermission = false
    
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
                            } else {
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
        .navigationDestination(isPresented: $showLocationPermission) {
            LocationPermissionView()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = uiImage
            }
        }
    }
}

#Preview {
    ProfilePictureView()
}
