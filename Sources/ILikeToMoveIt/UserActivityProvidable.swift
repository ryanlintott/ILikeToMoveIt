//
//  UserActivityProvidable.swift
//  ILikeToMoveIt
//
//  Created by Ryan Lintott on 2023-07-13.
//

import SwiftUI

/// A `Providable`object with that has an `NSUserActivity` property that will help it create new windows on iPadOS.
///
/// Make sure to add your activity type string to plist under `NSUserActivityTypes` and then use the    `onContinueUserActivity` overload function that takes a `UserActivityProvidable` object to handle what your app does when opened via this activity.
public protocol UserActivityProvidable: Providable {
    /// Type identifier for an associated user activity.
    ///
    /// Add this string value to your plist under NSUserActivityTypes
    static var activityType: String { get }
}

public extension UserActivityProvidable {
    init?(activity: NSUserActivity) {
        guard activity.activityType == Self.activityType else { return nil }
        guard
            let data = activity.targetContentIdentifier?.data(using: .utf8),
            let item = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = item
    }
    
    var userActivity: NSUserActivity? {
        if Self.activityType.isEmpty { return nil }
        guard
            let data = try? JSONEncoder().encode(self)
        else { return nil }
        let activity = NSUserActivity(activityType: Self.activityType)
        let string = String(data: data, encoding: .utf8)
        activity.targetContentIdentifier = string
        return activity
    }
}

public extension View {
    /// Registers a handler to invoke when a new scene is created by dropping the specified `UserActivityProvidable` type.
    /// - Parameters:
    ///   - item: The type of object that will envoke this handler.
    ///   - action: The handler that will run when the new scene is created with an optional item that was dropped. The item will be nil if there was an error in the encoding or decoding process.
    func onContinueUserActivity<T: UserActivityProvidable>(_ item: T.Type, perform action: @escaping (T?) -> Void ) -> some View {
        onContinueUserActivity(T.activityType) { activity in
            let item = T(activity: activity)
            action(item)
        }
    }
}
