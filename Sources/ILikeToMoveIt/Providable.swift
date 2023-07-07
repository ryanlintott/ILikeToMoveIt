//
//  Providable.swift
//  DragAndDrop
//
//  Created by Ryan Lintott on 2022-10-12.
//

import Foundation
import UniformTypeIdentifiers

public protocol Providable: Codable {
    static var writableTypes: [UTType] { get }
    static var readableTypes: [UTType] { get }
    
    func data(type: UTType) async throws -> Data?
    init?(type: UTType, data: Data) throws
}

extension Providable {
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
                    throw ProvidableError.unsupportedUTIIdentifier
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
            throw ProvidableError.unsupportedUTIIdentifier
        }
        return Self(item)
    }
}

public enum ProvidableError: Error {
    case unsupportedUTIIdentifier
}
