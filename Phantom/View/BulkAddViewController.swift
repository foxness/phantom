//
//  BulkAddViewController.swift
//  Phantom
//
//  Created by River on 2021/05/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class BulkAddViewController: UIViewController, BulkAddViewDelegate, UITextViewDelegate {
    enum Segue: String {
        case unwindBulkAdded = "unwindBulkAdded"
    }
    
    @IBOutlet var keyboardHeightConstraint: NSLayoutConstraint!
    private var bottomLeewayHeight: CGFloat! // height between the bottom of postsView and superview bottom
    
    @IBOutlet weak var bulkView: UITextView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    private let presenter = BulkAddPresenter()
    
    var bulkText: String? {
        get { bulkView.text }
        set { bulkView.text = newValue }
    }

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
    
    func setupViews() {
        bottomLeewayHeight = keyboardHeightConstraint.constant
        
        bulkView.becomeFirstResponder()
        bulkView.delegate = self
    }
    
    private func subscribeToKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardFrameTop = keyboardFrame?.origin.y ?? 0
        
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        if keyboardFrameTop >= UIScreen.main.bounds.size.height {
            keyboardHeightConstraint.constant = bottomLeewayHeight
        } else {
            keyboardHeightConstraint.constant = keyboardFrame?.size.height ?? 0
        }
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: animationCurve,
            animations: { self.view.layoutIfNeeded() },
            completion: nil
        )
    }
    
    func setAddButton(enabled: Bool) {
        addButton.isEnabled = enabled
    }
    
    func dismiss() {
        dismiss(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === addButton else { return }
        
        // todo: cancel segue if posts arent parsing
        
        presenter.addButtonPressed()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier == BulkAddViewController.Segue.unwindBulkAdded.rawValue
            && presenter.shouldPerformAddSegue()
    }
    
    func getResultingPosts() -> [BarePost]? {
        return presenter.posts
    }
    
    func getClipboard() -> String? { // todo: maybe refactor it into Helper or something
        return UIPasteboard.general.string
    }
    
    // MARK: - User interaction

    @IBAction func cancelButtonPressed(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
    
    @IBAction func textChanged(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
    
    @IBAction func pasteButtonPressed(_ sender: Any) {
        presenter.pasteButtonPressed()
    }
    
    // MARK: - Text view delegate
    
    func textViewDidChange(_ textView: UITextView) {
        presenter.textChanged()
    }
}
