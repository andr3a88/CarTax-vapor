//
//  extensions.swift
//  App
//
//  Created by Andrea Stevanato on 06/12/2018.
//

import Foundation

extension Optional where Wrapped == String {

    var nilIfEmpty: String? {
        guard let self = self else { return nil }
        return self.isEmpty ? nil : self
    }
}
