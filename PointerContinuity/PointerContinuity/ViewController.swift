//
//  ViewController.swift
//  PointerContinuity
//
//  Created by Christoph Parstorfer on 24.04.21.
//

import UIKit
import GameController

class ViewController: UIViewController {
    
    @IBOutlet private weak var mouseWarningLabel: UILabel!
    @IBOutlet private weak var switchPrefersLocked: UISwitch!
    @IBOutlet private weak var switchStateLocked: UISwitch!
    @IBOutlet private weak var buttonUnlockCursor: UIButton!
    private weak var externalButtonUnlockCursor: UIButton?
    private weak var pointerView: PointerView!
    
    private var pointerLocked = false
    private var lastKnownPointerPosition = CGPoint.zero

    override var prefersPointerLocked: Bool { pointerLocked }
    
    private func setPointerLocked(_ value: Bool) {
        pointerLocked = value
        switchPrefersLocked.isEnabled = !value
        buttonUnlockCursor.isEnabled = value
        self.externalButtonUnlockCursor?.isEnabled = value
        if !value {
            pointerView.pointerPosition = nil
            (UIApplication.shared.delegate as! AppDelegate).externalPointerView?.pointerPosition = nil
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
    
    private func setUnlockAlpha(_ alpha: CGFloat, withDuration dur: TimeInterval = 0.2) {
        UIView.animate(withDuration: dur) {
            self.buttonUnlockCursor.alpha = alpha
            self.externalButtonUnlockCursor?.alpha = alpha
        }
    }
    
    @IBAction func valueChanged(theSwitch: UISwitch) {
        setPointerLocked(theSwitch.isOn)
    }
    
    @IBAction func unlockCursorDown() {
        setUnlockAlpha(0.2)
    }
    
    @IBAction func unlockCursorUpOutside() {
        setUnlockAlpha(1)
    }
    
    @IBAction func unlockCursorUpInside() {
        setUnlockAlpha(1)
        setPointerLocked(false)
    }
    
    override func viewDidLoad() {
        (UIApplication.shared.delegate as! AppDelegate).viewController = self
        addKeyCommand(UIKeyCommand(action: #selector(onEsc), input: UIKeyCommand.inputEscape))
        let pointerView = PointerView()
        pointerView.setupCursorWithImage(UIImage(named: "defaultCursor")!)
        view.addSubview(pointerView)
        self.pointerView = pointerView
        pointerView.pointerPosition = nil
        let pointerInteraction = UIPointerInteraction(delegate: self)
        view.addInteraction(pointerInteraction)
        setPointerLocked(false)
        /// sign up for notifications about connected mouse
        NotificationCenter.default.addObserver(self, selector: #selector(cgMouseDidBecomeCurrent), name: .GCMouseDidBecomeCurrent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cgMouseDidStopBeingCurrent), name: .GCMouseDidStopBeingCurrent, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let scene = view.window!.windowScene else { return }
        switchStateLocked.setOn(scene.pointerLockState?.isLocked ?? false, animated: false)
        /// workaround for iOS behavior where the external display will not use the system appearance by default
        (UIApplication.shared.delegate as! AppDelegate).externalVC?.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
    }
    
    @objc private func cgMouseDidBecomeCurrent(_ notification: Notification) {
        if let mouseInput = (notification.object as? GCMouse)?.mouseInput {
            DispatchQueue.main.async { [self] in
                mouseInput.mouseMovedHandler = gcMouseMoved
                mouseInput.leftButton.pressedChangedHandler = gcMousePressed
                mouseWarningLabel.isHidden = true
            }
        }
    }
    
    @objc private func cgMouseDidStopBeingCurrent(_ notification: Notification) {
        DispatchQueue.main.async { [self] in
            setPointerLocked(false)
            mouseWarningLabel.isHidden = false
        }
    }

    private func gcMouseMoved(mouse: GCMouseInput, deltaX: Float, deltaY: Float) {
        if self.pointerLocked && (deltaX + deltaY) != 0.0 {
            self.handleLockedPointerMoved(CGFloat(deltaX), CGFloat(deltaY))
        }
    }
    
    private var lastClickedControl: UIControl? = nil
    
    /// basically re-implements UIControl touchDown, touchUpInside and touchUpOutside behavior
    private func gcMousePressed(input: GCControllerButtonInput, value: Float, isPressed: Bool) {
        func handleClickedView(_ hitView: UIView) {
            /// click down
            if isPressed, let control = hitView as? UIControl {
                lastClickedControl = control
                control.sendActions(for: .touchDown)
            } else if let lastClickedControl = lastClickedControl {
                /// click up
                if hitView == lastClickedControl {
                    lastClickedControl.sendActions(for: .touchUpInside)
                } else {
                    lastClickedControl.sendActions(for: .touchUpOutside)
                }
                self.lastClickedControl = nil
            }
        }
        
        if pointerLocked {
            /// determine if there is a UIControl at the clicked position on this view
            if let hitView = view.hitTest(lastKnownPointerPosition, with: nil) {
                handleClickedView(hitView)
            } else if !view.bounds.contains(lastKnownPointerPosition),
                      /// cursor is on external screen!
                      let extView = (UIApplication.shared.delegate as! AppDelegate).externalPointerView {
                let extPosition = lastKnownPointerPosition - extView.positionOffset
                /// hitTest does not work on external display :-(
                /*
                if let hitView = extView.hitTest(extPosition, with: nil) {
                    handleClickedView(hitView)
                }
                */
                /// since hitTest doesn't work, we need to check if the external unlock button's frame matches
                if let button = externalButtonUnlockCursor,
                   button.frame.contains(extPosition) {
                    handleClickedView(button)
                }
            }
        }
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
        setPointerLocked(false)
    }
    
}

extension ViewController: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        if !pointerLocked {
            lastKnownPointerPosition = request.location
        }
        return nil
    }
}

extension ViewController {
    public func createUnlockButton(for pointerView: PointerView) {
        let button = UIButton(primaryAction: UIAction.init(title: "Unlock cursor", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .mixed, handler: { action in
            print("Hello from the other side")
        }))
        button.setTitle("Unlock cursor", for: .normal)
        button.titleLabel!.font = UIFont.preferredFont(forTextStyle: .headline)
        button.translatesAutoresizingMaskIntoConstraints = false
        pointerView.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: pointerView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: pointerView.centerYAnchor)
        ])
        button.addTarget(self, action: #selector(unlockCursorDown), for: .touchDown)
        button.addTarget(self, action: #selector(unlockCursorUpOutside), for: .touchUpOutside)
        button.addTarget(self, action: #selector(unlockCursorUpInside), for: .touchUpInside)
        button.isEnabled = pointerLocked
        button.backgroundColor = .systemBackground
        externalButtonUnlockCursor = button
    }
}

extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
