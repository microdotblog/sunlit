import Foundation

enum CheckInPostDelay: Int, CaseIterable {
    case noDelay = 0
    case oneHour = 3600
    case twoHours = 7200
    case oneDay = 86400

    private static let settingsKey = "SunlitCheckInPostDelay"
    private static let resetWarningKey = "SunlitCheckInPostDelayResetWarning"
    static let resetWarningMessage = "The scheduled check-in delay has been reset to 1 day. Longer delays are no longer available."

    static var needsResetWarning: Bool {
        get { Settings.object(forKey: self.resetWarningKey) as? Bool ?? false }
        set { Settings.setValue(newValue, forKey: self.resetWarningKey) }
    }

    @discardableResult
    static func resetUnsupportedDelayIfNeeded() -> Bool {
        // Stored values for the former 2-day, 3-day, and 1-week choices.
        guard let value = Settings.object(forKey: self.settingsKey) as? Int,
              [172800, 259200, 604800].contains(value) else { return false }
        self.selected = .oneDay
        self.needsResetWarning = true
        return true
    }

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
        }
    }

    func publishedDate(from now: Date = Date()) -> Date {
        return now.addingTimeInterval(TimeInterval(self.rawValue))
    }
}
