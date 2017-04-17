//
//  LazyVectorExtension.swift
//  FindCityFB
//
//  Created by Maxim Zaks on 25.04.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

extension FlatBuffersTableVector {
    
    public func itemsWithStringPrefix(_ prefix : String, stringExtractor : @escaping (T)->String) -> CountableRange<Int> {
        
        func start(_ _left : Int,_ _right : Int,_ _mid : Int) -> Int {
            var left = _left
            var right = _right
            var result = _mid
            while((left <= right)){
                let mid = (right + left) >> 1
                if(stringExtractor(self[mid]!).hasPrefix(prefix)){
                    result = mid
                    right = mid - 1
                } else if (stringExtractor(self[mid]!) <= prefix){
                    left = mid + 1
                } else {
                    right = mid - 1
                }
            }
            return result
        }
        
        func end(_ _left : Int,_ _right : Int,_ _mid : Int) -> Int {
            var left = _left
            var right = _right
            var result = _mid
            while((left <= right)){
                let mid = (right + left) >> 1
                if(stringExtractor(self[mid]!).hasPrefix(prefix)){
                    result = mid
                    left = mid + 1
                } else if (stringExtractor(self[mid]!) <= prefix){
                    left = mid + 1
                } else {
                    right = mid - 1
                }
            }
            return result
        }
        
        var left : Int = 0
        var right : Int = self.count - 1
        while((left <= right)) {
            let mid = (right + left) >> 1
            if(stringExtractor(self[mid]!).hasPrefix(prefix)){
                return start(left, right, mid)..<(end(left, right, mid)+1)
            } else if (stringExtractor(self[mid]!) <= prefix){
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        return 0..<0
    }
}
