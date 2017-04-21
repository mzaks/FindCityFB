//
//  LazyVectorExtension.swift
//  FindCityFB
//
//  Created by Maxim Zaks on 25.04.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

extension FlatBuffersTableVector {
    
    enum PrefixResult {
        case Equal, Smaller, Bigger
    }
    
    public func itemsWithStringPrefix(_ prefix : String, bufferExtractor : @escaping (T?)->UnsafeBufferPointer<UInt8>?) -> CountableRange<Int> {
        
        func computePrefix(buffer : UnsafeBufferPointer<UInt8>?, prefix: String) -> PrefixResult{
            guard let buffer = buffer else {return .Smaller}
            var i = 0
            for c in prefix.utf8 {
                guard i < buffer.count else {return .Smaller}
                if buffer[i] < c  {
                    return .Smaller
                }
                if buffer[i] > c  {
                    return .Bigger
                }
                i += 1
            }
            return .Equal
        }
        
        func start(_ _left : Int,_ _right : Int,_ _mid : Int) -> Int {
            var left = _left
            var right = _right
            var result = _mid
            while((left <= right)){
                let mid = (right + left) >> 1
                let prefixResult = computePrefix(buffer:bufferExtractor(self[mid]),prefix:prefix)
                switch prefixResult {
                case .Equal:
                    result = mid
                    right = mid - 1
                case .Smaller:
                    left = mid + 1
                case .Bigger:
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
                
                let prefixResult = computePrefix(buffer:bufferExtractor(self[mid]),prefix:prefix)
                switch prefixResult {
                case .Equal:
                    result = mid
                    left = mid + 1
                case .Smaller:
                    left = mid + 1
                case .Bigger:
                    right = mid - 1
                }
            }
            return result
        }
        
        var left : Int = 0
        var right : Int = self.count - 1
        while((left <= right)) {
            let mid = (right + left) >> 1
            
            let prefixResult = computePrefix(buffer:bufferExtractor(self[mid]),prefix:prefix)
            switch prefixResult {
            case .Equal:
                return start(left, right, mid)..<(end(left, right, mid)+1)
            case .Smaller:
                left = mid + 1
            case .Bigger:
                right = mid - 1
            }
        }
        
        return 0..<0
    }
}
