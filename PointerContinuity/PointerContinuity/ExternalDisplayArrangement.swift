//
//  ExternalDisplayArrangement.swift
//  PointerContinuity
//
//  Created by Christoph Parstorfer on 25.04.21.
//

import UIKit


struct ExternalDisplayArrangement {
    enum Edge {
        case leading, top, trailing, bottom
    }
    
    var edge: Edge
    var externalBounds: CGRect
}


extension ExternalDisplayArrangement {
    static func PlacedRelativeToMainScreen(_ mainScreen: UIScreen, at edge: Edge, externalScreen: UIScreen) -> ExternalDisplayArrangement {
        let mainSize = mainScreen.bounds.size
        let externalSize = externalScreen.bounds.size
        var (x, y): (CGFloat, CGFloat) = (0, 0)
        switch edge {
        case .leading:
            x = -externalSize.width
            y = (mainSize.height - externalSize.height) / 2
        case .top:
            x = (mainSize.width - externalSize.width) / 2
            y = -externalSize.height
        case .trailing:
            x = mainSize.width
            y = (mainSize.height - externalSize.height) / 2
        case .bottom:
            x = (mainSize.width - externalSize.width) / 2
            y = mainSize.height
        }
        
        return ExternalDisplayArrangement(edge: edge,
                                          externalBounds: CGRect(
                                            x: x,
                                            y: y,
                                            width: externalSize.width,
                                            height: externalSize.height))
    }
}
