//
//  LevelMap.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 19.01.2022.
//

import SpriteKit

class LevelMap: Hashable {
    let page: Int
    var sprite: SKSpriteNode?
    var buttons: [CMButtonNode] = []
    var multiplier: CGFloat
    
    init(page: Int, multiplier: CGFloat) {
        self.page = page
        self.multiplier = multiplier
    }
    
    static func ==(lhs: LevelMap, rhs: LevelMap) -> Bool {
        return lhs.page == rhs.page
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(page)
    }
}
