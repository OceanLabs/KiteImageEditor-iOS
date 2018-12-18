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

@objc public class KiteImageEditor: NSObject {
    
    static let editorBundle = Bundle(for: KiteImageEditor.self)
    static let editorResourceBundle: Bundle = {
        guard let resourcePath = editorBundle.path(forResource: "KiteImageEditorResources", ofType: "bundle"),
            let resourceBundle = Bundle(path: resourcePath)
            else {
                return editorBundle
        }
        
        return resourceBundle
    }()
    
    @objc public static func editor(with image: UIImage, delegate: KiteImageEditorDelegate? = nil, aspectRatio: CGFloat = 1.0, minimumResolution: CGFloat = 0.0) -> UIViewController {
        let storyBoard = UIStoryboard(name: "KiteImageEditor", bundle: editorResourceBundle)
        let editorNavigationController = storyBoard.instantiateViewController(withIdentifier: "KiteImageEditorNavigationController") as! UINavigationController
        let editorViewController = editorNavigationController.viewControllers.first as! KiteImageEditorViewController
        editorViewController.image =  image
        editorViewController.containerRatio = aspectRatio
        editorViewController.minimumImageResolution = minimumResolution > 0.0 ? minimumResolution : nil
        editorViewController.delegate = delegate
        return editorNavigationController
    }
}
