import Foundation

struct Language: Identifiable {
    let id: String
    let name: String
    let flag: String
    let isoCode: String
    
    init(name: String, flag: String, isoCode: String) {
        self.name = name
        self.flag = flag
        self.isoCode = isoCode
        self.id = isoCode
    }
}

enum LanguageDatabase {
    static let all: [Language] = [
        Language(name: "Afrikaans", flag: "🇿🇦", isoCode: "af"),
        Language(name: "Albanian", flag: "🇦🇱", isoCode: "sq"),
        Language(name: "Amharic", flag: "🇪🇹", isoCode: "am"),
        Language(name: "Arabic", flag: "🇸🇦", isoCode: "ar"),
        Language(name: "Armenian", flag: "🇦🇲", isoCode: "hy"),
        Language(name: "Azerbaijani", flag: "🇦🇿", isoCode: "az"),
        Language(name: "Bengali", flag: "🇧🇩", isoCode: "bn"),
        Language(name: "Bosnian", flag: "🇧🇦", isoCode: "bs"),
        Language(name: "Bulgarian", flag: "🇧🇬", isoCode: "bg"),
        Language(name: "Catalan", flag: "🇦🇩", isoCode: "ca"),
        Language(name: "Chinese (Mandarin)", flag: "🇨🇳", isoCode: "zh"),
        Language(name: "Croatian", flag: "🇭🇷", isoCode: "hr"),
        Language(name: "Czech", flag: "🇨🇿", isoCode: "cs"),
        Language(name: "Danish", flag: "🇩🇰", isoCode: "da"),
        Language(name: "Dutch", flag: "🇳🇱", isoCode: "nl"),
        Language(name: "English", flag: "🇺🇸", isoCode: "en"),
        Language(name: "Estonian", flag: "🇪🇪", isoCode: "et"),
        Language(name: "Finnish", flag: "🇫🇮", isoCode: "fi"),
        Language(name: "French", flag: "🇫🇷", isoCode: "fr"),
        Language(name: "Georgian", flag: "🇬🇪", isoCode: "ka"),
        Language(name: "German", flag: "🇩🇪", isoCode: "de"),
        Language(name: "Greek", flag: "🇬🇷", isoCode: "el"),
        Language(name: "Gujarati", flag: "🇮🇳", isoCode: "gu"),
        Language(name: "Haitian Creole", flag: "🇭🇹", isoCode: "ht"),
        Language(name: "Hebrew", flag: "🇮🇱", isoCode: "he"),
        Language(name: "Hindi", flag: "🇮🇳", isoCode: "hi"),
        Language(name: "Hungarian", flag: "🇭🇺", isoCode: "hu"),
        Language(name: "Icelandic", flag: "🇮🇸", isoCode: "is"),
        Language(name: "Indonesian", flag: "🇮🇩", isoCode: "id"),
        Language(name: "Irish", flag: "🇮🇪", isoCode: "ga"),
        Language(name: "Italian", flag: "🇮🇹", isoCode: "it"),
        Language(name: "Japanese", flag: "🇯🇵", isoCode: "ja"),
        Language(name: "Kannada", flag: "🇮🇳", isoCode: "kn"),
        Language(name: "Kazakh", flag: "🇰🇿", isoCode: "kk"),
        Language(name: "Khmer", flag: "🇰🇭", isoCode: "km"),
        Language(name: "Korean", flag: "🇰🇷", isoCode: "ko"),
        Language(name: "Kurdish", flag: "🇮🇶", isoCode: "ku"),
        Language(name: "Lao", flag: "🇱🇦", isoCode: "lo"),
        Language(name: "Latvian", flag: "🇱🇻", isoCode: "lv"),
        Language(name: "Lithuanian", flag: "🇱🇹", isoCode: "lt"),
        Language(name: "Macedonian", flag: "🇲🇰", isoCode: "mk"),
        Language(name: "Malay", flag: "🇲🇾", isoCode: "ms"),
        Language(name: "Malayalam", flag: "🇮🇳", isoCode: "ml"),
        Language(name: "Maltese", flag: "🇲🇹", isoCode: "mt"),
        Language(name: "Maori", flag: "🇳🇿", isoCode: "mi"),
        Language(name: "Marathi", flag: "🇮🇳", isoCode: "mr"),
        Language(name: "Mongolian", flag: "🇲🇳", isoCode: "mn"),
        Language(name: "Nepali", flag: "🇳🇵", isoCode: "ne"),
        Language(name: "Norwegian", flag: "🇳🇴", isoCode: "nb"),
        Language(name: "Pashto", flag: "🇦🇫", isoCode: "ps"),
        Language(name: "Persian", flag: "🇮🇷", isoCode: "fa"),
        Language(name: "Polish", flag: "🇵🇱", isoCode: "pl"),
        Language(name: "Portuguese", flag: "🇵🇹", isoCode: "pt"),
        Language(name: "Punjabi", flag: "🇮🇳", isoCode: "pa"),
        Language(name: "Romanian", flag: "🇷🇴", isoCode: "ro"),
        Language(name: "Russian", flag: "🇷🇺", isoCode: "ru"),
        Language(name: "Serbian", flag: "🇷🇸", isoCode: "sr"),
        Language(name: "Sinhala", flag: "🇱🇰", isoCode: "si"),
        Language(name: "Slovak", flag: "🇸🇰", isoCode: "sk"),
        Language(name: "Slovenian", flag: "🇸🇮", isoCode: "sl"),
        Language(name: "Somali", flag: "🇸🇴", isoCode: "so"),
        Language(name: "Spanish", flag: "🇪🇸", isoCode: "es"),
        Language(name: "Swahili", flag: "🇰🇪", isoCode: "sw"),
        Language(name: "Swedish", flag: "🇸🇪", isoCode: "sv"),
        Language(name: "Tagalog", flag: "🇵🇭", isoCode: "tl"),
        Language(name: "Tamil", flag: "🇮🇳", isoCode: "ta"),
        Language(name: "Telugu", flag: "🇮🇳", isoCode: "te"),
        Language(name: "Thai", flag: "🇹🇭", isoCode: "th"),
        Language(name: "Turkish", flag: "🇹🇷", isoCode: "tr"),
        Language(name: "Ukrainian", flag: "🇺🇦", isoCode: "uk"),
        Language(name: "Urdu", flag: "🇵🇰", isoCode: "ur"),
        Language(name: "Uzbek", flag: "🇺🇿", isoCode: "uz"),
        Language(name: "Vietnamese", flag: "🇻🇳", isoCode: "vi"),
        Language(name: "Welsh", flag: "🇬🇧", isoCode: "cy"),
        Language(name: "Xhosa", flag: "🇿🇦", isoCode: "xh"),
        Language(name: "Yoruba", flag: "🇳🇬", isoCode: "yo"),
        Language(name: "Zulu", flag: "🇿🇦", isoCode: "zu")
    ]
}
