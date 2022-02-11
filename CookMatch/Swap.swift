//
//  Swap.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 21.12.2021.
//

struct Swap: CustomStringConvertible, Hashable {
    let cookieA: Cookie
    let cookieB: Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
    
    var description: String {
        return "Swap \(cookieA) with \(cookieB)"
    }
    
    static func ==(lhs: Swap, rhs: Swap) -> Bool {
        return (lhs.cookieA == rhs.cookieA && lhs.cookieB == rhs.cookieB) || (lhs.cookieB == rhs.cookieA && lhs.cookieA == rhs.cookieB)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(cookieA.hashValue ^ cookieB.hashValue)
    }
}
