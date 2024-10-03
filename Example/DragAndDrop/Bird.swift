//
//  Bird.swift
//  DragAndDrop
//
//  Created by Ryan Lintott on 2022-10-11.
//

import Foundation

struct Bird: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

extension Bird {
    static let examples: [Self] = [
        "Cardinal",
        "Blue Jay",
        "Robin",
        "Goose",
        "Chicken",
        "Swan",
        "Flamingo"
    ].map { Bird(name: $0)}
}
