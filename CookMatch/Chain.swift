//
//  Chain.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 24.12.2021.
//

class Chain: CustomStringConvertible, Hashable {
    var cookies: [Cookie] = []
    var score = 0
    
    enum ChainType: CustomStringConvertible {
        case tiltedRight
        case tiltedLeft
        
        var description: String {
            switch self {
            case .tiltedRight:
                return "Tilted Right"
            case .tiltedLeft:
                return "Tilted Left"
            }
        }
    }
    
    var chainType: ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func addCookie(_ cookie: Cookie) {
        cookies.append(cookie)
    }
    
    func firstCookie() -> Cookie {
        return cookies[0]
    }
    
    func lastCookie() -> Cookie {
        return cookies[cookies.count - 1]
    }
    
    var length: Int {
        return cookies.count
    }
    
    var description: String {
        return "Type:\(chainType), Cookies:\(cookies)"
    }
    
    static func ==(lhs: Chain, rhs: Chain) -> Bool {
        return lhs.cookies == rhs.cookies
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(cookies.reduce(0) {
            $0.hashValue ^ $1.hashValue
        })
    }
}
