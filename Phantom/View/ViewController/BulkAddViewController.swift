//
//  BulkAddViewController.swift
//  Phantom
//
//  Created by River on 2021/05/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class BulkAddViewController: UIViewController, BulkAddViewDelegate, UITextViewDelegate {
    // MARK: - Segue
    
    enum Segue: String {
        case unwindBulkAdded = "unwindBulkAdded"
    }
    
    // MARK: - Constants
    
    private static let textColor = UIColor.label
    private static let placeholderColor = UIColor.secondaryLabel
    
    private static let placeholderText = "Majestic cat Minnie\nhttps://i.imgur.com/8sDuIVu.jpeg\n\nCool video\nhttps://www.youtube.com/watch?v=dQw4w9WgXcQ\n\nTitle goes here\nLink goes here\n\n...\n..."
    
    // MARK: - Views
    
    @IBOutlet var keyboardHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bulkView: UITextView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    private var bottomLeewayHeight: CGFloat! // height between the bottom of postsView and superview bottom
    private let presenter = BulkAddPresenter()
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToKeyboardNotification()
        setupViews()
        
        presenter.attachView(self)
        presenter.viewDidLoad()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    private func setupViews() {
        bottomLeewayHeight = keyboardHeightConstraint.constant
        
        BulkAddViewController.placeholderify(bulkView)
        bulkView.becomeFirstResponder()
        
        bulkView.delegate = self
    }
    
    // MARK: - Keyboard notification
    
    private func subscribeToKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animationCurveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        let keyboardShown = keyboardFrame.origin.y < UIScreen.main.bounds.size.height
        if keyboardShown {
            keyboardHeightConstraint.constant = keyboardFrame.size.height
        } else {
            keyboardHeightConstraint.constant = bottomLeewayHeight
        }
        
        let delay: TimeInterval = 0
        let animations = { self.view.layoutIfNeeded() }
        
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: animationCurve,
                       animations: animations,
                       completion: nil)
    }
    
    // MARK: - Bulk Add view delegate
    
    var bulkText: String? {
        get {
            return bulkView.textColor == BulkAddViewController.placeholderColor ? "" : bulkView.text
        }
        
        set {
            if newValue == nil || newValue == "" {
                BulkAddViewController.placeholderify(bulkView)
            } else {
                bulkView.textColor = BulkAddViewController.textColor
                bulkView.text = newValue
            }
        }
    }
    
    func setAddButton(enabled: Bool) {
        addButton.isEnabled = enabled
    }
    
    func segueBack() {
        segueTo(.unwindBulkAdded)
    }
    
    func showInvalidSyntaxAlert() {
        let title = "Error"
        let message = "Invalid post syntax"
        displayOkAlert(title: title, message: message)
    }
    
    // MARK: - Navigation
    
    func segueTo(_ segue: Segue) {
        performSegue(withIdentifier: segue.rawValue, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard segue.identifier == Segue.unwindBulkAdded.rawValue else { fatalError() }
        
//        guard let button = sender as? UIBarButtonItem, button === addButton else { return }
//
//        // todo: tell user if posts arent parsing
//
//        presenter.addButtonPressed()
    }
    
    func getResultingPosts() -> [BulkPost]? {
        return presenter.posts
    }
    
    // MARK: - User interaction

    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func pasteButtonPressed(_ sender: Any) {
        presenter.pasteButtonPressed()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        presenter.addButtonPressed()
    }
    
    // MARK: - Text view delegate
    
    // Bulk Add text view placeholder
    // src: https://stackoverflow.com/a/27652289/1412924
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText: String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        if updatedText.isEmpty {
            BulkAddViewController.placeholderify(textView)
            
            presenter.textChanged() // do not move this because it should be after changing textColor
            return false
        }
        else if textView.textColor == BulkAddViewController.placeholderColor && !text.isEmpty {
            textView.textColor = BulkAddViewController.textColor
            textView.text = text
            
            presenter.textChanged() // do not move this
            return false
        }
        
        presenter.textChanged()
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard view.window != nil else { return }
        guard textView.textColor == BulkAddViewController.placeholderColor else { return }
        
        BulkAddViewController.moveCursorToBeginning(textView)
    }
    
    private static func placeholderify(_ textView: UITextView) {
        textView.textColor = BulkAddViewController.placeholderColor
        textView.text = BulkAddViewController.placeholderText
        BulkAddViewController.moveCursorToBeginning(textView)
    }
    
    private static func moveCursorToBeginning(_ textView: UITextView) {
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument,
                                                        to: textView.beginningOfDocument)
    }
}
