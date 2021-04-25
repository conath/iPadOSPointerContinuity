//
//  ViewController.swift
//  PointerContinuity
//
//  Created by Christoph Parstorfer on 24.04.21.
//

import UIKit
import GameController

class ViewController: UIViewController {
    
    @IBOutlet private weak var switchPrefersLocked: UISwitch!
    @IBOutlet private weak var switchStateLocked: UISwitch!
    @IBOutlet private weak var mouseWarningLabel: UILabel!
    private weak var pointerView: PointerView!
    
    private var pointerLocked = false
    private var lastKnownPointerPosition = CGPoint.zero

    override var prefersPointerLocked: Bool { pointerLocked }
    
    private func setPointerLocked(value: Bool) {
        pointerLocked = value
        if !value {
            pointerView.pointerPosition = nil
        }
        setNeedsUpdateOfPrefersPointerLocked()
        let isOnScreen = view.window != nil
        switchPrefersLocked.setOn(value, animated: isOnScreen)
        if isOnScreen, let scene = view.window!.windowScene {
            /// the UIPointerLockState takes more than three run loops to update!
            /// measured on iPad Pro with A12X ¯\_(ツ)_/¯
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [self] in
                let isReallyLocked = scene.pointerLockState?.isLocked ?? false
                switchStateLocked.setOn(isReallyLocked, animated: true)
            }
        }
    }
    
    @IBAction func valueChanged(theSwitch: UISwitch) {
        setPointerLocked(value: theSwitch.isOn)
    }
    
    override func viewDidLoad() {
        addKeyCommand(UIKeyCommand(action: #selector(onEsc), input: UIKeyCommand.inputEscape))
        let pointerView = PointerView()
        pointerView.setupCursorWithImage(UIImage(named: "defaultCursor")!)
        view.addSubview(pointerView)
        self.pointerView = pointerView
        pointerView.pointerPosition = nil
        let pointerInteraction = UIPointerInteraction(delegate: self)
        view.addInteraction(pointerInteraction)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switchPrefersLocked.setOn(prefersPointerLocked, animated: false)
        /// set up mouse events
        guard let scene = view.window!.windowScene else { return }
        switchStateLocked.setOn(scene.pointerLockState?.isLocked ?? false, animated: false)
        if let mouseInput = GCMouse.current?.mouseInput {
            mouseInput.mouseMovedHandler = { [weak self] (mouse: GCMouseInput, deltaX: Float, deltaY: Float) in
                guard let self = self else { return }
                /// let's hope we're on the main thread
                if self.pointerLocked {
                    self.handleLockedPointerMoved(CGFloat(deltaX), CGFloat(deltaY))
                }
            }
            mouseWarningLabel.isHidden = true
        }
        /// workaround for iOS behavior where the external display will not use the system appearance by default
        (UIApplication.shared.delegate as! AppDelegate).externalVC?.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
    }
    
    private func handleLockedPointerMoved(_ deltaX: CGFloat, _ deltaY: CGFloat) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let sensitivity: CGFloat = 2.0/3.0
        var pX = self.lastKnownPointerPosition.x + deltaX * sensitivity
        /// y axis is inverted compared to UIKit
        var pY = self.lastKnownPointerPosition.y - deltaY * sensitivity
        let pos = CGPoint(x: pX, y: pY)
        /// is pointer within the view bounds?
        if view.bounds.contains(pos) {
            lastKnownPointerPosition = pos
            pointerView.pointerPosition = pos
            appDelegate.externalPointerView?.pointerPosition = nil
        } else {
            func clampToInternal() {
                pX = max(0.0, min(self.view.bounds.width, pX))
                pY = max(0.0, min(self.view.bounds.height, pY))
                lastKnownPointerPosition = CGPoint(x: pX, y: pY)
                pointerView.pointerPosition = lastKnownPointerPosition
            }
            /// is external connected?
            if let displayArrangement = appDelegate.externalDisplayArrangement {
                let externalPointerView = appDelegate.externalPointerView!
                let previouslyOnExternal = externalPointerView.pointerPosition != nil
                /// pointer on external view?
                if displayArrangement.externalBounds.contains(pos) {
                    lastKnownPointerPosition = pos
                    externalPointerView.pointerPosition = pos
                    pointerView.pointerPosition = nil
                }
                /// pointer previously external and not on internal?
                else if !view.bounds.contains(pos) && previouslyOnExternal {
                    /// on external edge ==> need to clamp value!
                    /// easier calculation: pretend the external screen is at (0,0)
                    pX -= displayArrangement.externalBounds.origin.x
                    pY -= displayArrangement.externalBounds.origin.y
                    /// Limit the pointer to the external view
                    pX = max(0.0, min(displayArrangement.externalBounds.width, pX))
                    pY = max(0.0, min(displayArrangement.externalBounds.height, pY))
                    pX += displayArrangement.externalBounds.origin.x
                    pY += displayArrangement.externalBounds.origin.y
                    lastKnownPointerPosition = CGPoint(x: pX, y: pY)
                    externalPointerView.pointerPosition = lastKnownPointerPosition
                    pointerView.pointerPosition = nil
                } else {
                    clampToInternal()
                    externalPointerView.pointerPosition = nil
                }
            } else {
                clampToInternal()
            }
        }
    }
    
    @objc private func onEsc() {
        setPointerLocked(value: false)
    }
    
}

extension ViewController: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        lastKnownPointerPosition = request.location
        return nil
    }
}
