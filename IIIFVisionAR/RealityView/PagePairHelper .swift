//
//  PagePairHelper .swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 9/8/23.
//

import Foundation

extension Collection {
    /// Build pair for book representation
    /// Add (nil, nil) pair at the front to ensure the page start from the rightSide.
    /// Add (nil, nil) pair to the end if the input is even number, to ensure we can scroll the last page to the leftSide.
    /// Example:
    /// Input: [1, 2, 3, 4]
    /// Output: [(nil, nil), (1, 2), (3, 4), (nil, nil)]
    /// Input: [1, 2, 3]
    /// Output: [(nil, nil), (1, 2), (3, nil)]
    func buildPagePairs() -> [(Element?, Element?)] {
        var pairOutput: [(Element?, Element?)] = [(nil, nil)]

        // Build pair output from iterator
        var iterator = self.makeIterator()

        while let leftElement = iterator.next() {
            let rightElement = iterator.next()
            pairOutput.append((leftElement, rightElement))
        }

        // Add (nil, nil) pair to the end if the input is even number, to ensure we can scroll the last page to the leftSide.
        // To optimize the performance to O(1), we check if the last pair's rightElement is not nil (we have even count of input), add (nil, nil) pair to the end
        if pairOutput.last?.1 != nil {
            pairOutput.append((nil, nil))
        }

        return pairOutput
    }
}
