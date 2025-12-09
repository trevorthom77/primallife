//
//  WelcomeProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 12/1/25.
//

import SwiftUI
import Supabase

struct WelcomeProfileView: View {
    @Environment(\.supabaseClient) private var supabase
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to your profile")
                            .font(.onboardingTitle)
                            .foregroundColor(Colors.primaryText)
                        Text("This is how others will see you.")
                            .font(.travelBody)
                            .foregroundColor(Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    ProfilePreviewCard()
                }
                .padding(20)
                .padding(.top, 48)
                .padding(.bottom, 180)
            }
            
            VStack(spacing: 16) {
                Button {
                    Task {
                        await saveProfile()
                    }
                } label: {
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
        .navigationBarBackButtonHidden(true)
    }
    
    private func saveProfile() async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        
        struct OnboardingPayload: Encodable {
            let user_id: String
            let full_name: String
            let birthday: String
            let origin: String?
            let gender: String?
            let bio: String
            let avatar_url: String?
            let meeting_preference: String?
            let meeting_up_preference: String?
            let split_expenses_preference: String?
            let travel_description: String?
            let upcoming_destination: String
            let upcoming_arrival_date: String?
            let upcoming_departing_date: String?
            let languages: [String]
            let interests: [String]
            let completed_at: String
        }
        
        let payload = OnboardingPayload(
            user_id: "\(userID)",
            full_name: onboardingViewModel.name,
            birthday: onboardingViewModel.birthday.ISO8601Format(),
            origin: onboardingViewModel.selectedCountryID,
            gender: onboardingViewModel.selectedGender,
            bio: onboardingViewModel.bio,
            avatar_url: onboardingViewModel.avatarPath,
            meeting_preference: onboardingViewModel.travelCompanionPreference,
            meeting_up_preference: onboardingViewModel.meetingStyle,
            split_expenses_preference: onboardingViewModel.splitExpensesPreference,
            travel_description: onboardingViewModel.travelDescription,
            upcoming_destination: onboardingViewModel.upcomingDestination,
            upcoming_arrival_date: onboardingViewModel.hasSelectedArrival ? onboardingViewModel.arrivalDate.ISO8601Format() : nil,
            upcoming_departing_date: onboardingViewModel.hasSelectedDeparting ? onboardingViewModel.departingDate.ISO8601Format() : nil,
            languages: Array(onboardingViewModel.selectedLanguageIDs),
            interests: Array(onboardingViewModel.selectedInterests),
            completed_at: Date().ISO8601Format()
        )
        
        do {
            try await supabase
                .from("onboarding")
                .upsert(payload, onConflict: "user_id")
                .execute()
        } catch {
            print("Profile save failed: \(error)")
        }
    }
}

private struct ProfilePreviewCard: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @Environment(\.supabaseClient) private var supabase
    var avatarURL: URL? = nil
    @State private var signedAvatarURL: URL?
    @State private var destinationImageURL: URL?
    @State private var destinationPhotographerName: String?
    @State private var destinationPhotographerProfileURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(onboardingViewModel.name)
                            .font(.customTitle)
                            .foregroundColor(Colors.primaryText)
                    }
                    
                    if let originText = originText {
                        Text(originText)
                            .font(.travelDetail)
                            .foregroundColor(Colors.secondaryText)
                    }
                    
                    if let ageText = ageText {
                        Text(ageText)
                            .font(.travelDetail)
                            .foregroundColor(Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                avatarImage
            }
            
            if let tagText = tagText {
                HStack {
                    Text(tagText)
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Colors.accent)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
            
            if let aboutText = aboutText {
                VStack(alignment: .leading, spacing: 10) {
                    Text("About")
                        .font(.travelDetail)
                        .foregroundColor(Colors.secondaryText)
                    Text(aboutText)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                }
            }
            
            if let destinationLabel = destinationText {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Next stop")
                        .font(.travelDetail)
                        .foregroundColor(Colors.secondaryText)
                    
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(destinationLabel)
                                .font(.travelBody)
                                .foregroundColor(Colors.primaryText)
                            
                            if let tripDateText = tripDateText {
                                Text(tripDateText)
                                    .font(.travelDetail)
                                    .foregroundColor(Colors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            if let name = destinationPhotographerName,
                               let profileURL = destinationPhotographerProfileURL {
                                Link(name, destination: profileURL)
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            
                            ZStack {
                                if let destinationImageURL {
                                    AsyncImage(url: destinationImageURL) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Colors.card
                                    }
                                } else {
                                    Colors.card
                                }
                            }
                            .frame(width: 140, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .task(id: destinationText) {
                        guard let destinationQuery = destinationText else {
                            destinationImageURL = nil
                            destinationPhotographerName = nil
                            destinationPhotographerProfileURL = nil
                            return
                        }
                        
                        let details = await UnsplashService.fetchImageDetails(for: destinationQuery)
                        destinationImageURL = details?.url
                        destinationPhotographerName = details?.photographerName
                        destinationPhotographerProfileURL = details?.photographerProfileURL
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.card)
        .cornerRadius(16)
        .task {
            await loadSignedAvatarIfNeeded()
        }
    }
    
    private var originText: String? {
        guard
            let selectedCountryID = onboardingViewModel.selectedCountryID,
            let country = CountryDatabase.all.first(where: { $0.id == selectedCountryID })
        else { return nil }
        
        return "\(country.flag) \(country.name)"
    }
    
    private var ageText: String? {
        guard onboardingViewModel.hasSelectedBirthday else { return nil }
        let age = Calendar.current.dateComponents([.year], from: onboardingViewModel.birthday, to: Date()).year ?? 0
        return age > 0 ? "Age \(age)" : nil
    }
    
    private var tagText: String? {
        if let description = onboardingViewModel.travelDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
           !description.isEmpty {
            return description
        }
        
        if let interest = onboardingViewModel.selectedInterests.first {
            return interest
        }
        
        return nil
    }
    
    private var aboutText: String? {
        let trimmed = onboardingViewModel.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private var destinationText: String? {
        let trimmed = onboardingViewModel.upcomingDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private var tripDateText: String? {
        let formatter = Date.FormatStyle(date: .abbreviated, time: .omitted)
        
        if onboardingViewModel.hasSelectedArrival, onboardingViewModel.hasSelectedDeparting {
            let arrival = onboardingViewModel.arrivalDate.formatted(formatter)
            let departing = onboardingViewModel.departingDate.formatted(formatter)
            return "\(arrival)–\(departing)"
        }
        
        if onboardingViewModel.hasSelectedArrival {
            return onboardingViewModel.arrivalDate.formatted(formatter)
        }
        
        if onboardingViewModel.hasSelectedDeparting {
            return onboardingViewModel.departingDate.formatted(formatter)
        }
        
        return nil
    }
    
    private var resolvedAvatarURL: URL? {
        avatarURL ?? signedAvatarURL
    }
    
    private var avatarImage: some View {
        Group {
            if let data = onboardingViewModel.profileImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let resolvedAvatarURL {
                AsyncImage(url: resolvedAvatarURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.clear
                }
            } else {
                Image("travel29")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 104, height: 104)
        .clipShape(Circle())
    }
    
    private func loadSignedAvatarIfNeeded() async {
        guard signedAvatarURL == nil,
              avatarURL == nil,
              let path = onboardingViewModel.avatarPath,
              let supabase else { return }
        
        do {
            let url = try await supabase.storage
                .from("profile-photos")
                .createSignedURL(path: path, expiresIn: 3600)
            
            await MainActor.run {
                signedAvatarURL = url
            }
        } catch {
            print("Failed to create signed avatar URL: \(error)")
        }
    }
}

#Preview {
    WelcomeProfileView()
        .environmentObject(OnboardingViewModel())
}
