//
//  BaseResponseType.swift
//  App
//
//  Created by Andrea Stevanato on 04/12/2018.
//

import Vapor

protocol BaseResponseType: Content {

    var status: String? { get set }
}

protocol BaseItemResponseType: Codable {

    associatedtype D
    var item: D { get set }
}

protocol BaseItemsResponseType: Codable {

    associatedtype D
    var items: D { get set }
}

struct ItemResponse<T: Content>: BaseResponseType, BaseItemResponseType {

    typealias D = T

    // MARK: Properties

    var status: String?
    var item: T

    // MARK: Methods

    init(item: T) {
        self.item = item
        self.status = "ok"
    }
}
