//
//  Providable.swift
//  DragAndDrop
//
//  Created by Ryan Lintott on 2022-10-12.
//

import Foundation
import UniformTypeIdentifiers

/// An object with that has an `NSItemProvider` property that can be used in `.onDrag`,  `.onDrop`, and `.onInsert` view modifiers in SwiftUI. It can be read and/or written to a set number of unique types.
public protocol Providable: Codable {
    /// An array of types that this object can be written to.
    static var writableTypes: [UTType] { get }
    /// An array of types that this object can be read from.
    static var readableTypes: [UTType] { get }
    
    
    /// Returns a data representation of this object based on the specified type.
    /// - Parameter type: Type to use when converting to Data.
    /// - Returns: A data representation of this object based on the specified type.
    func data(type: UTType) async throws -> Data?
    
    /// Creates an object based on data converted using the specified type.
    /// - Parameters:
    ///   - type: Type to use when converting from Data.
    ///   - data: Data representation used when creating the object.
    init?(type: UTType, data: Data) throws
}

extension Providable {
    /// An `NSItemProvider` object based on this object.
    public var provider: NSItemProvider {
        .init(object: ItemProvider(self))
    }
    
    public static func load(from provider: NSItemProvider, completionHandler: @escaping (Self?, Error?) -> Void) {
        provider.loadItem(Self.self, completionHandler: completionHandler)
    }
    
    static func writableType(identifier: String) -> UTType? {
        writableTypes.first { $0.identifier == identifier }
    }
    
    static func readableType(identifier: String) -> UTType? {
        readableTypes.first { $0.identifier == identifier }
    }
}

public extension NSItemProvider {
    /// Loads a `Providable` item from this `NSItemProvider`
    /// - Parameters:
    ///   - itemType: Providable item type
    ///   - completionHandler: Closure to run when an item is found or an error returned.
    func loadItem<T: Providable>(_ itemType: T.Type, completionHandler: @escaping (T?, Error?) -> Void) {
        if canLoadObject(ofClass: ItemProvider<T>.self) {
            _ = loadObject(ofClass: ItemProvider<T>.self) { itemProvider, error in
                if let error {
                    completionHandler(nil, error)
                    return
                }
                if let itemProvider = itemProvider as? ItemProvider<T> {
                    completionHandler(itemProvider.item, nil)
                } else {
                    completionHandler(nil, DecodingError.typeMismatch(ItemProvider<T>.self, .init(codingPath: [], debugDescription: "Type of NSItemProviderReading does not match expected object type.")))
                }
            }
        }
    }
}

public extension [NSItemProvider] {
    /// Loads a `Providable` items in sequence from this array of `NSItemProvider`
    /// - Parameters:
    ///   - itemType: Providable item type
    ///   - completionHandler: Closure to run when each item is found or error is returned.
    func loadItems<T: Providable>(_ itemType: T.Type, completionHandler: @escaping (T?, Error?) -> Void) {
        forEach { provider in
            provider.loadItem(itemType, completionHandler: completionHandler)
        }
    }
}

class ItemProvider<Item: Providable>: NSObject, NSItemProviderWriting, NSItemProviderReading {
    var item: Item
    
    required init(_ item: Item) {
        self.item = item
        super.init()
    }
    
    static var writableTypeIdentifiersForItemProvider: [String] {
        Item.writableTypes.map(\.identifier)
    }

    static var readableTypeIdentifiersForItemProvider: [String] {
        Item.readableTypes.map(\.identifier)
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Progress? {
        Task {
            do {
                guard
                    let type = Item.writableType(identifier: typeIdentifier),
                    let data = try await item.data(type: type) else {
                    throw ProvidableError.unsupportedUTTypeIdentifier
                }
                completionHandler(data, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
        
        return Progress(totalUnitCount: 100)
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        guard
            let type = Item.readableType(identifier: typeIdentifier),
            let item = try Item(type: type, data: data) else {
            throw ProvidableError.unsupportedUTTypeIdentifier
        }
        return Self(item)
    }
}

public enum ProvidableError: LocalizedError {
    case unsupportedUTTypeIdentifier
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedUTTypeIdentifier:
            return "Unsupported UTType identifier"
        }
    }
}
