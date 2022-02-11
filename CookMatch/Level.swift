//
//  Level.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 17.12.2021.
//

let numColumns = 9
let numRows = 9
let numLevels = 4

class Level {
    private var cookies = Array2D<Cookie>(columns: numColumns, rows: numRows)
    private var tiles = Array2D<Tile>(columns: numColumns, rows: numRows)
    private var possibleSwaps: Set<Swap> = []
    private var comboMultiplier = 0
    
    var target: [String:Int] = [:]
    var moves = 0
    
    init(filename: String) {
        guard let levelData = LevelData.loadFrom(filename: filename) else {
            return
        }
        
        let tilesArray = levelData.tiles
        
        for (row, rowArray) in tilesArray.enumerated() {
            let tileRow = numRows - row - 1
            
            for (column, value) in rowArray.enumerated() {
                if value == 1 {
                    tiles[column, tileRow] = Tile()
                }
            }
        }
        
        target = levelData.target
        moves = levelData.moves
    }
    
    func cookieAt(column: Int, row: Int) -> Cookie? {
        precondition(column >= 0 && column < numColumns)
        precondition(row >= 0 && row < numRows)
        return cookies[column, row]
    }
    
    func tileAt(column: Int, row: Int) -> Tile? {
        precondition(column >= 0 && column < numColumns)
        precondition(row >= 0 && row < numRows)
        return tiles[column, row]
    }
    
    func shuffle() -> Set<Cookie> {
        var set: Set<Cookie>
        repeat {
            set = createInitialCookies()
            detectPossibleSwaps()
        } while possibleSwaps.count == 0
        
        return set
    }
    
    private func createInitialCookies() -> Set<Cookie> {
        var set: Set<Cookie> = []
        
        for row in 0..<numRows {
            for column in 0..<numColumns {
                if tiles[column, row] != nil {
                    var cookieType: CookieType
                    repeat {
                        cookieType = CookieType.random()
                    } while (row >= 2 && column <= numColumns - 3 && cookies[column + 1, row - 1]?.cookieType == cookieType && cookies[column + 2, row - 2]?.cookieType == cookieType) || (row >= 2 && column >= 2 && cookies[column - 1, row - 1]?.cookieType == cookieType && cookies[column - 2, row - 2]?.cookieType == cookieType)
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    
                    set.insert(cookie)
                }
            }
        }
        
        return set
    }
    
    func performSwap(_ swap: Swap) {
        let columnA = swap.cookieA.column
        let rowA = swap.cookieA.row
        let columnB = swap.cookieB.column
        let rowB = swap.cookieB.row
        
        cookies[columnA, rowA] = swap.cookieB
        swap.cookieB.column = columnA
        swap.cookieB.row = rowA
        
        cookies[columnB, rowB] = swap.cookieA
        swap.cookieA.column = columnB
        swap.cookieA.row = rowB
    }
    
    private func hasChainAt(column: Int, row: Int) -> Bool {
        let cookieType = cookies[column, row]!.cookieType
        
        // Tilted right
        var tiltedRightLength = 1
        
        // Up
        var iC = column + 1
        var iR = row + 1
        while iC < numColumns && iR < numRows && cookies[iC, iR]?.cookieType == cookieType {
            iC += 1
            iR += 1
            tiltedRightLength += 1
        }
        
        // Down
        iC = column - 1
        iR = row - 1
        while iC >= 0 && iR >= 0 && cookies[iC, iR]?.cookieType == cookieType {
            iC -= 1
            iR -= 1
            tiltedRightLength += 1
        }
        
        if tiltedRightLength >= 3 {
            return true
        }
        
        // Tilted left
        var tiltedLeftLength = 1
        
        // Up
        iC = column - 1
        iR = row + 1
        while iC >= 0 && iR < numRows && cookies[iC, iR]?.cookieType == cookieType {
            iC -= 1
            iR += 1
            tiltedLeftLength += 1
        }
        
        // Down
        iC = column + 1
        iR = row - 1
        while iC < numColumns && iR >= 0 && cookies[iC, iR]?.cookieType == cookieType {
            iC += 1
            iR -= 1
            tiltedLeftLength += 1
        }
        
        return tiltedLeftLength >= 3
    }
    
    func detectPossibleSwaps() {
        var set: Set<Swap> = []
        
        for row in 0..<numRows {
            for column in 0..<numColumns {
                if let cookie = cookies[column, row] {
                    if column < numColumns - 1, let other = cookies[column + 1, row] {
                        cookies[column, row] = other
                        cookies[column + 1, row] = cookie
                        
                        if hasChainAt(column: column + 1, row: row) || hasChainAt(column: column, row: row) {
                            set.insert(Swap(cookieA: cookie, cookieB: other))
                        }
                        
                        cookies[column, row] = cookie
                        cookies[column + 1, row] = other
                    }
                    
                    if row < numRows - 1, let other = cookies[column, row + 1] {
                        cookies[column, row] = other
                        cookies[column, row + 1] = cookie
                        
                        if hasChainAt(column: column, row: row + 1) || hasChainAt(column: column, row: row) {
                            set.insert(Swap(cookieA: cookie, cookieB: other))
                        }
                        
                        cookies[column, row] = cookie
                        cookies[column, row + 1] = other
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    func getPossibleSwapsCount() -> Int {
        return possibleSwaps.count
    }
    
    private func detectTiltedRightMatches() -> Set<Chain> {
        var set: Set<Chain> = []
        
        for row in 0..<numRows - 2 {
            var column = 0
            
            while column < numColumns - 2 {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    if cookies[column + 1, row + 1]?.cookieType == matchType && cookies[column + 2, row + 2]?.cookieType == matchType {
                        var createChain = true
                        for chain in set {
                            if chain.cookies.contains(cookies[column + 1, row + 1]!) && chain.cookies.contains(cookies[column + 2, row + 2]!) {
                                createChain = false
                            }
                        }
                        
                        if createChain {
                            let chain = Chain(chainType: .tiltedRight)
                            var column_ = column
                            var row_ = row
                            
                            repeat {
                                chain.addCookie(cookies[column_, row_]!)
                                column_ += 1
                                row_ += 1
                            } while column_ < numColumns && row_ < numRows && cookies[column_, row_]?.cookieType == matchType
                            
                            set.insert(chain)
                        }
                    }
                }
                
                column += 1
            }
        }
        
        return set
    }
    
    private func detectTiltedLeftMatches() -> Set<Chain> {
        var set: Set<Chain> = []
        
        for row in 0..<numRows - 2 {
            var column = 2
            
            while column < numColumns {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    if cookies[column - 1, row + 1]?.cookieType == matchType && cookies[column - 2, row + 2]?.cookieType == matchType {
                        var createChain = true
                        for chain in set {
                            if chain.cookies.contains(cookies[column - 1, row + 1]!) && chain.cookies.contains(cookies[column - 2, row + 2]!) {
                                createChain = false
                            }
                        }
                        
                        if createChain {
                            let chain = Chain(chainType: .tiltedLeft)
                            var column_ = column
                            var row_ = row
                            
                            repeat {
                                chain.addCookie(cookies[column_, row_]!)
                                column_ -= 1
                                row_ += 1
                            } while column_ > -1 && row_ < numRows && cookies[column_, row_]?.cookieType == matchType
                            
                            set.insert(chain)
                        }
                    }
                }
                
                column += 1
            }
        }
        
        return set
    }
    
    func removeMatches() -> Set<Chain> {
        let tiltedRightChains = detectTiltedRightMatches()
        let tiltedLeftChains = detectTiltedLeftMatches()
        
        removeCookies(in: tiltedRightChains)
        removeCookies(in: tiltedLeftChains)
        
        calculateScores(for: tiltedRightChains)
        calculateScores(for: tiltedLeftChains)
        
        return tiltedRightChains.union(tiltedLeftChains)
    }
    
    private func removeCookies(in chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.column, cookie.row] = nil
            }
        }
    }
    
    func fillHoles() -> [[Cookie]] {
        var columns: [[Cookie]] = []
        
        for column in 0..<numColumns {
            var array: [Cookie] = []
            
            for row in 0..<numRows {
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    for lookup in (row + 1)..<numRows {
                        if let cookie = cookies[column, lookup] {
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            
                            array.append(cookie)
                            
                            break
                        }
                    }
                }
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        
        return columns
    }
    
    func topUpCookies() -> [[Cookie]] {
        var columns: [[Cookie]] = []
        
        for column in 0..<numColumns {
            var array: [Cookie] = []
            
            var row = numRows - 1
            while row >= 0 && cookies[column, row] == nil {
                if tiles[column, row] != nil {
                    let cookie = Cookie(column: column, row: row, cookieType: CookieType.random())
                    cookies[column, row] = cookie
                    array.append(cookie)
                }
                
                row -= 1
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        
        return columns
    }
    
    private func calculateScores(for chains: Set<Chain>) {
        for chain in chains {
            chain.score = 70 * (chain.length - 2) * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
}
