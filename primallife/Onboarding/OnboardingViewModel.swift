import SwiftUI
import Combine

final class OnboardingViewModel: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var name = ""
    @Published var birthday = Date()
    @Published var hasSelectedBirthday = false
    @Published var hasAcceptedTerms = false
    
    @Published var selectedLanguageIDs: Set<String> = []
    @Published var selectedCountryID: String?
    @Published var selectedGender: String?
    @Published var travelCompanionPreference: String?
    @Published var meetingStyle: String?
    @Published var selectedInterests: Set<String> = []
    @Published var travelDescription: String?
    
    @Published var bio = ""
    
    @Published var upcomingDestination = ""
    @Published var arrivalDate = Date()
    @Published var hasSelectedArrival = false
    @Published var departingDate = Date()
    @Published var hasSelectedDeparting = false
    
    @Published var profileImageData: Data?
    @Published var avatarPath: String?
}
