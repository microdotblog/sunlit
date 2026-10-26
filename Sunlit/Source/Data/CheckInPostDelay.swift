import Foundation

enum CheckInPostDelay: Int, CaseIterable {
    case noDelay = 0
    case oneHour = 3600
    case twoHours = 7200
    case oneDay = 86400
    case twoDays = 172800
    case threeDays = 259200
    case oneWeek = 604800

    private static let settingsKey = "SunlitCheckInPostDelay"

    static var selected: CheckInPostDelay {
        get {
            let value = Settings.object(forKey: self.settingsKey) as? Int ?? 0
            return CheckInPostDelay(rawValue: value) ?? .noDelay
        }
        set {
            Settings.setValue(newValue.rawValue, forKey: self.settingsKey)
        }
    }

    var title: String {
        switch self {
        case .noDelay: return "No delay"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .oneDay: return "1 day"
        case .twoDays: return "2 days"
        case .threeDays: return "3 days"
        case .oneWeek: return "1 week"
        }
    }

    func publishedDate(from now: Date = Date()) -> Date {
        return now.addingTimeInterval(TimeInterval(self.rawValue))
    }
}
