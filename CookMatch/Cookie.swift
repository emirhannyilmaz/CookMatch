//
//  Cookie.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 17.12.2021.
//

import SpriteKit

enum CookieType: Int, CustomStringConvertible {
    case unknown = 0, croissant, cupcake, danish, donut, macaroon, sugarCookie
    
    var spriteName: String {
        let spriteNames = [
            "Croissant",
            "Cupcake",
            "Danish",
            "Donut",
            "Macaroon",
            "SugarCookie"
        ]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    
    var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .croissant:
            return "croissant"
        case .cupcake:
            return "cupcake"
        case .danish:
            return "danish"
        case .donut:
            return "donut"
        case .macaroon:
            return "macaroon"
        case .sugarCookie:
            return "sugarCookie"
        }
    }
}

class Cookie: CustomStringConvertible, Hashable {
    var column: Int
    var row: Int
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, cookieType: CookieType) {
        self.column = column
        self.row = row
        self.cookieType = cookieType
    }
    
    var description: String {
        return "Type:\(cookieType) Square:(\(column), \(row))"
    }
    
    static func ==(lhs: Cookie, rhs: Cookie) -> Bool {
        return lhs.column == rhs.column && lhs.row == rhs.row
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(row * 10 + column)
    }
}
