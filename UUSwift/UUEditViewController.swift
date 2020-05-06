//
//  UUEditViewController
//  Useful Utilities - Subclass of UIViewController that handles automatically
//  some common editing tasks
//
//    License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  UUEditViewController has two main functions:
//
//  1) Handles taps to the root view and ends editing
//  2) Handles keyboard show/hide notifications and moves the view frame to
//     place the edit field right above the keyboard

#if os(iOS)

import UIKit

open class UUEditViewController : UIViewController
{
    var currentEditFieldFrame: CGRect? = nil
    var currentKeyboardFrame: CGRect? = nil
    var spaceToKeybaord : CGFloat = 10
    
    private var frameBeforeAdjust: CGRect? = nil
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
    }
    
    override open func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        registerNotificationHandlers()
    }
    
    override open func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        clearNotificationHandlers()
    }
    
    func referenceViewForEditField(_ view: UIView) -> UIView
    {
        return view
    }
    
    func registerNotificationHandlers()
    {
		NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil, using: handleKeyboardWillShowNotification)
		NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: handleKeyboardWillHideNotification)
		NotificationCenter.default.addObserver(forName: UITextView.textDidBeginEditingNotification, object: nil, queue: nil, using: handleEditingStarted)
		NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification, object: nil, queue: nil, using: handleEditingStarted)
		NotificationCenter.default.addObserver(forName: UITextView.textDidEndEditingNotification, object: nil, queue: nil, using: handleEditingEnded)
		NotificationCenter.default.addObserver(forName: UITextField.textDidEndEditingNotification, object: nil, queue: nil, using: handleEditingEnded)
    }
    
    func clearNotificationHandlers()
    {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleBackgroundTap()
    {
        view.endEditing(true)
    }
    
    @objc func handleKeyboardWillShowNotification(_ notification: Notification)
    {
		currentKeyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        animateViewIfNeeded()
    }
    
    private func animateViewIfNeeded()
    {
        if (currentKeyboardFrame != nil &&
            currentEditFieldFrame != nil &&
            isViewLoaded &&
            !view.isHidden)
        {
            let keyboardTop = currentKeyboardFrame!.origin.y
            let fieldBottom = currentEditFieldFrame!.origin.y + currentEditFieldFrame!.size.height
            
            if (keyboardTop < fieldBottom)
            {
                let keyboardAdjust = fieldBottom - keyboardTop + spaceToKeybaord
                
                var f = view.frame
                frameBeforeAdjust = f
                
                f.origin.y = -keyboardAdjust
                
                UIView.animate(withDuration: 0.5, animations:
                {
                    self.view.frame = f
                })
            }
        }
    }
    
    @objc func handleKeyboardWillHideNotification(_ notification: Notification)
    {
        currentKeyboardFrame = nil
        
        var f = view.frame
        
        if (frameBeforeAdjust != nil && f.origin.y != frameBeforeAdjust!.origin.y)
        {
            f.origin.y = frameBeforeAdjust!.origin.y
            
            UIView.animate(withDuration: 0.5, animations:
            {
                self.view.frame = f
            })
        }
    }
    
    @objc func handleEditingStarted(_ notification: Notification)
    {
        if let view = notification.object as? UIView
        {
            let refView = referenceViewForEditField(view)
            currentEditFieldFrame = refView.convert(refView.frame, to: view)
            animateViewIfNeeded()
        }
    }
    
    @objc func handleEditingEnded(_ notification: Notification)
    {
        currentEditFieldFrame = nil
    }
}

#endif
