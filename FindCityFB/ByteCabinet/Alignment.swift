//
//  Alignment.swift
//  ByteCabinet
//
//  Created by Maxim Zaks on 06.09.17.
//

import Foundation

func align<T:FixedWidthInteger>(cursor: T, additionalBytes : T) -> T {
    let size = additionalBytes > 8 ? 8 : additionalBytes
    let alignSize = ((~(cursor + additionalBytes)) + 1) & (size - 1)
    return alignSize
}
