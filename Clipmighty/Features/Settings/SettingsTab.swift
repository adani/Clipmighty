import Foundation

enum SettingsTab: String, Hashable {
    static let userDefaultsKey = "settingsSelectedTab"

    case general
    case rules
    case sync
    case about
}
