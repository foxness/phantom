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
        get { bulkView.text }
        set { bulkView.text = newValue }
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
    
    func textViewDidChange(_ textView: UITextView) {
        presenter.textChanged()
    }
}
