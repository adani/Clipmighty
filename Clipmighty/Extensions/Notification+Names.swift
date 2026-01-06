//
//  Notification+Names.swift
//  Clipmighty
//
//  Custom notification names used throughout the app.
//

import Foundation

// MARK: - Custom Notification Names
extension Notification.Name {
    /// Posted when the user toggles the "ignore concealed content" setting
    static let ignoreConcealedContentChanged = Notification.Name("ignoreConcealedContentChanged")
}
