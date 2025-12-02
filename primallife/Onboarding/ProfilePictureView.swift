import SwiftUI
import PhotosUI

struct ProfilePictureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?
    
    private let sampleImages = ["profile1", "profile2", "profile3", "profile4", "profile5", "profile6"]
    private let sampleLabels: [String: String] = [
        "profile1": "🇺🇸 Ava",
        "profile2": "🇬🇧 Kara",
        "profile3": "🇧🇷 Leo"
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add your profile photo")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Pick a clear photo of your face.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                sampleRow(images: Array(sampleImages.prefix(3)))
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Colors.card)
                            .frame(height: 240)
                        
                        if let image = profileImage {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
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
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button { } label: {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                
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
    }
    
    private func sampleRow(images: [String]) -> some View {
        HStack(spacing: 12) {
            ForEach(images, id: \.self) { name in
                ZStack(alignment: .bottomLeading) {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text(sampleLabels[name] ?? "")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .padding(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = Image(uiImage: uiImage)
            }
        }
    }
}

#Preview {
    ProfilePictureView()
}
