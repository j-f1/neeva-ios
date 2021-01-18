//
//  AbstractController.swift
//  
//
//  Created by Jed Fox on 1/18/21.
//

import SwiftUI

/// Contains functionality used by both `QueryController` and `MutationController`
public class AbstractController: ObservableObject {
    var animation: Animation?
    
    public init(animation: Animation? = nil) {
        self.animation = animation
    }

    /// Calls `body` inside of `withAnimation` if `animation` is non-`nil`. Otherwise, it calls `body` directly.
    func withOptionalAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
        if let animation = animation {
            return try withAnimation(animation, body)
        } else {
            return try body()
        }
    }

}
