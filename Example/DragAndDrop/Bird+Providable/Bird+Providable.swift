//
//  Bird+Providable.swift
//  DragAndDrop
//
//  Created by Ryan Lintott on 2023-07-03.
//

import Foundation
import ILikeToMoveIt
import UniformTypeIdentifiers

extension Bird: Providable {
    static let writableTypes: [UTType] = [.bird]

    static let readableTypes: [UTType] = [.bird, .utf8PlainText, .plainText]

    func data(type: UTType) throws-> Data? {
        switch type {
        case .bird:
            return try JSONEncoder().encode(self)
        default:
            return nil
        }
    }

    init?(type: UTType, data: Data) throws {
        switch type {
        case .bird:
            self = try JSONDecoder().decode(Bird.self, from: data)
        case .utf8PlainText, .plainText:
            let string = String(decoding: data, as: UTF8.self)
            self = Bird(name: string)
        default:
            return nil
        }
    }
}

extension Bird: UserActivityProvidable {
    static let activityType = "com.ryanlintott.draganddrop.birdDetail"
}
