//
//  LevelData.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 17.12.2021.
//

import Foundation

class LevelData: Codable {
    let tiles: [[Int]]
    let target: [String:Int]
    let moves: Int
  
    static func loadFrom(filename: String) -> LevelData? {
        var data: Data
        var levelData: LevelData?
    
        if let path = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                data = try Data(contentsOf: path)
            } catch {
                print("Couldn't load level file: \(filename), error: \(error)")
                return nil
            }
            
            do {
                levelData = try JSONDecoder().decode(LevelData.self, from: data)
            } catch {
                print("Level file '\(filename)' is not valid JSON: \(error)")
                return nil
            }
        }
        
        return levelData
    }
}
