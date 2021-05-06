//
//  PointerView.swift
//  PointerContinuity
//
//  Created by Christoph Parstorfer on 25.04.21.
//

import UIKit

class PointerView: UIView {
    // MARK: - API
    /// The absolute pointer position in points. Set to `nil` to hide the cursor.
    /// Make sure to update this after layout changes, as those are not tracked by this view.
    public var pointerPosition: CGPoint? = nil {
        didSet {
            pointerPosChanged()
        }
    }
    /// Offset to subtract from the `pointerPosition`
    public var positionOffset: CGPoint = CGPoint.zero
    
    public func setupCursorWithImage(_ image: UIImage) {
        setupImageView(image: image)
    }
    
    // MARK: - Implementation
    /// Offset the image from the pointer location so the pointer doesn't visually disappear at screen edges
    private let imageOffset = CGPoint(x: -2, y: -2)
    
    private var imageView: UIImageView!
    
    override func didMoveToSuperview() {
        if let superview = superview {
            translatesAutoresizingMaskIntoConstraints = false
            isUserInteractionEnabled = false
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                topAnchor.constraint(equalTo: superview.topAnchor),
                trailingAnchor.constraint(equalTo: superview.trailingAnchor),
                bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ])
        } else {
            pointerPosition = nil
        }
    }
    
    private func setupImageView(image: UIImage) {
        imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        imageView.frame.origin = pointerPosition ?? CGPoint.zero
        imageView.isHidden = pointerPosition != nil
    }
    
    private func pointerPosChanged() {
        if let position = pointerPosition {
            imageView.isHidden = false
            let x = position.x - positionOffset.x + imageOffset.x
            let y = position.y - positionOffset.y + imageOffset.y
            UIView.animate(withDuration: 1/60) { [self] in
                imageView.frame.origin = CGPoint(x: x, y: y)
            }
        } else {
            imageView.isHidden = true
        }
    }
}
