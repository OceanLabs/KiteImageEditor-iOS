//
//  MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

@objc public protocol KiteImageEditorDelegate: class {
    @objc func KiteImageEditorCancelledEditing()
    @objc func KiteImageEditorSavedEdits(to image: UIImage)
}

class ImageEditorViewController: UIViewController {
    
    private struct Constants {
        static let toolButtonCornerRadius: CGFloat = 10.0
        static let toolbarButtonUnselectedColor = UIColor(red: 51 / 255.0, green: 50 / 255.0, blue: 51 / 255.0, alpha: 1.0)
        static let toolbarButtonSelectedColor = UIColor(red: 78 / 255.0, green: 79 / 255.0, blue: 78 / 255.0, alpha: 1.0)
    }
    
    // Toolbar
    @IBOutlet private var toolbarButtons: [UIButton]! {
        didSet {
            for button in toolbarButtons {
                button.backgroundColor = Constants.toolbarButtonUnselectedColor
            }
        }
    }
    
    // Image placement area
    @IBOutlet private weak var assetEditingAreaView: UIView!
    @IBOutlet private weak var assetContainerView: UIView!
    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet weak var lowResolutionMessageView: UIView!
    
    @IBOutlet weak var assetContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var assetContainerViewHeightConstraint: NSLayoutConstraint!
    
    private var maxScale: CGFloat!
    private var transform = CGAffineTransform.identity
    private var isFlipped = false
    private var hasDoneSetup = false

    var containerRatio: CGFloat = 1.0
    var image: UIImage!
    var minimumImageResolution: CGFloat!
    
    weak var delegate: KiteImageEditorDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController == nil {
            fatalError("ImageEditorViewController: Please use a navigation controller or alternatively, set the 'embedInNavigation' parameter to true.")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        toolbarButtons[0].round(corners: [.topLeft, .bottomLeft], radius: Constants.toolButtonCornerRadius)
        toolbarButtons[2].round(corners: [.topRight, .bottomRight], radius: Constants.toolButtonCornerRadius)
        
        setUp()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { _ in
            self.updateUI()
        }, completion: nil)
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    private func setUp() {
        guard !hasDoneSetup else { return }
        hasDoneSetup = true
        
        updateUI()
    }
    
    func updateUI() {
        setupContainerView()
        setUpImageView()
    }
    
    private func setupContainerView() {
        
        // Calculate new container size
        var width: CGFloat
        var height: CGFloat
        let maxWidth = assetEditingAreaView.bounds.width
        
        if containerRatio >= 1.0 && !view.bounds.size.isLandscape() { // Landscape
            width = maxWidth
            height = width / containerRatio
        } else { // Portrait
            height = assetEditingAreaView.bounds.height
            width = height * containerRatio
            if width >= maxWidth {
                width = maxWidth
                height = maxWidth / containerRatio
            }
        }
        
        assetContainerViewWidthConstraint.constant = width
        assetContainerViewHeightConstraint.constant = height
        
        assetEditingAreaView.layoutIfNeeded()
    }
    
    private func setUpImageView() {
        assetImageView.frame = CGRect(origin: .zero, size: image.size)
        assetImageView.center = CGPoint(x: assetContainerView.bounds.width * 0.5, y: assetContainerView.bounds.height * 0.5)
        assetImageView.image = image

        fitAssetToContainer()
        assetImageView.transform = transform
        
        // Allow scaling up to 3 times the original scale
        let startingScale = LayoutUtils.scaleToFill(containerSize: assetContainerView.bounds.size, withSize: image.size, atAngle: 0)
        maxScale = startingScale * 3.0
        
        // Show low resolution message if needed
        lowResolutionMessageView.alpha = minimumImageResolution != nil && (image.size.width * image.size.height < minimumImageResolution) ? 1.0 : 0.0
    }
    
    // MARK: - Gestures
    private var initialTransform: CGAffineTransform?
    private var gestures = Set<UIGestureRecognizer>(minimumCapacity: 3)
    
    private func startedRotationGesture(_ gesture: UIRotationGestureRecognizer, inView view: UIView) {
        let location = gesture.location(in: view)
        let normalised = CGPoint(x: location.x / view.bounds.width, y: location.y / view.bounds.height)
        setAnchorPoint(anchorPoint: normalised, view: view)
    }
    
    private func setAnchorPoint(anchorPoint: CGPoint, view: UIView) {
        let oldOrigin = view.frame.origin
        view.layer.anchorPoint = anchorPoint
        let newOrigin = view.frame.origin
        
        let transition = CGPoint(x: newOrigin.x - oldOrigin.x, y: newOrigin.y - oldOrigin.y)
        view.center = CGPoint(x: view.center.x - transition.x, y: view.center.y - transition.y)
    }
    
    @IBAction private func processTransform(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            if gestures.isEmpty { initialTransform = assetImageView.transform }
            gestures.insert(gesture)
            if let gesture = gesture as? UIRotationGestureRecognizer {
                startedRotationGesture(gesture, inView: assetImageView)
            }
        case .changed:
            if var initial = initialTransform {
                gestures.forEach({ (gesture) in initial = LayoutUtils.adjustTransform(initial, withRecognizer: gesture, inParentView: assetContainerView, maxScale: maxScale) })
                assetImageView.transform = initial
            }
        case .ended:
            gestures.remove(gesture)
            if gestures.isEmpty {
                setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5), view: assetImageView)
                
                assetImageView.transform = LayoutUtils.centerTransform(assetImageView.transform, inParentView: assetContainerView, fromPoint: assetImageView.center)
                assetImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
                
                transform = LayoutUtils.adjustTransform(assetImageView.transform, forViewSize: image.size, inContainerSize: assetContainerView.bounds.size)
                
                animateTransformToFill()
            }
        default:
            break
        }
    }
    
    private func animateTransformToFill() {
        // The keyframe animation prevents a known bug where the UI jumps when animating to a new transform
        UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: [ .calculationModeCubicPaced ], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0, animations: {
                self.assetImageView.transform = self.transform
            })
        }, completion: nil)
    }
    
    private func fitAssetToContainer() {
        // Calculate scale. Ignore any previous translation
        let angle = transform.angle
        let scale = LayoutUtils.scaleToFill(containerSize: assetContainerView.bounds.size, withSize: image.size, atAngle: angle)
        transform = CGAffineTransform.identity.rotated(by: angle).scaledBy(x: scale, y: scale)
    }
    
    private func rotateCCW() {
        let rotateTo = LayoutUtils.nextCCWCuadrantAngle(to: transform.angle)
        
        let scale = LayoutUtils.scaleToFill(containerSize: assetContainerView.bounds.size, withSize: image.size, atAngle: rotateTo)
        transform = CGAffineTransform.identity.rotated(by: rotateTo).scaledBy(x: scale, y: scale)
    }
    
    private func cropEditedImage() -> UIImage {
        let originalImageSize = image.size
        let scaleToFinalContainerSize = 1.0 / transform.scale
        let targetSize = assetContainerView.bounds.size * scaleToFinalContainerSize
        
        var scaledTransform = LayoutUtils.adjustTransform(transform, byFactorX: scaleToFinalContainerSize, factorY: scaleToFinalContainerSize)
        scaledTransform = LayoutUtils.adjustTransform(scaledTransform, forViewSize: originalImageSize, inContainerSize: targetSize)
        
        let tempContainerView = UIView(frame: CGRect(origin: .zero, size: targetSize))
        tempContainerView.clipsToBounds = true
        
        let tempImageView = UIImageView(frame: CGRect(origin: .zero, size: originalImageSize))
        tempImageView.center = CGPoint(x: tempContainerView.bounds.midX, y: tempContainerView.bounds.midY)
        tempImageView.image = image
        tempImageView.transform = scaledTransform
        
        tempContainerView.addSubview(tempImageView)
        view.addSubview(tempContainerView)
        
        let editedImage = tempContainerView.snapshot()
        tempContainerView.removeFromSuperview()
        
        if isFlipped {
            return editedImage.withHorizontallyFlippedOrientation()
        }
        
        return editedImage
    }
    
    // MARK: - Toolbar actions
    
    @IBAction private func toolButtonTouchDown(_ sender: UIButton) {
        sender.backgroundColor = Constants.toolbarButtonSelectedColor
    }
    
    @IBAction private func toolButtonTouchUp(_ sender: UIButton) {
        sender.backgroundColor = Constants.toolbarButtonUnselectedColor
    }
    
    @IBAction private func scaleToFill(_ sender: UIButton) {
        fitAssetToContainer()
        animateTransformToFill()
    }
    
    @IBAction private func rotate(_ sender: UIButton) {
        rotateCCW()
        animateTransformToFill()
    }
    
    @IBAction private func flip(_ sender: UIButton) {
        isFlipped = !isFlipped
        assetContainerView.flipY()
    }
    
    // MARK: - Navigation bar actions
    
    @IBAction private func tappedCancelButton(_ sender: UIBarButtonItem) {
        delegate?.KiteImageEditorCancelledEditing()
    }
    
    @IBAction private func tappedSaveButton(_ sender: UIBarButtonItem) {
        let editedImage = cropEditedImage()
        delegate?.KiteImageEditorSavedEdits(to: editedImage)
    }
}

extension ImageEditorViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
