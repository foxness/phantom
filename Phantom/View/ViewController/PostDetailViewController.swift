//
//  PostDetailViewController.swift
//  Phantom
//
//  Created by Rivershy on 2020/08/30.
//  Copyright © 2020 Rivershy. All rights reserved.
//

import UIKit

// todo: make title and content text fields multiline

class PostDetailViewController: UIViewController, PostDetailViewDelegate, UITextFieldDelegate {
    enum Segue: String {
        case unwindPostSaved = "unwindPostSaved"
    }
    
    private static let TEXT_NEW_POST_TITLE = "New Post"
    private static let TEXT_SELF_PLACEHOLDER = "Add text (optional)"
    private static let TEXT_LINK_PLACEHOLDER = "Add URL"
    
    private static let MAX_SUBREDDIT_LENGTH = Reddit.LIMIT_SUBREDDIT_LENGTH
    private static let SUBREDDIT_ALLOWED_CHARACTERS = NSCharacterSet(charactersIn: "ABCDEFGHIJKLMONPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") // do not use NSCharacterSet.alphanumerics because it contains non-latin alphanumerics which we don't want
    
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var pasteButton: UIButton!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentField: UITextField!
    @IBOutlet weak var subredditField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var subredditPrefixLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    private let presenter = PostDetailPresenter()
    
    var postTitle: String {
        PostDetailViewController.emptyIfNull(titleField.text?.trim())
    }
    
    var postSubreddit: String {
        PostDetailViewController.emptyIfNull(subredditField.text?.trim())
    }
    
    var postDate: Date {
        datePicker.date
    }
    
    var postType: Post.PostType {
        typeControl.selectedSegmentIndex == 0 ? .link : .text
    }
    
    var postUrl: String? {
        contentField.text?.trim()
    }
    
    var postText: String? {
        contentField.text?.trim()
    }
    
    func setSaveButton(enabled: Bool) {
        saveButton.isEnabled = enabled
    }
    
    func supplyPost(_ post: Post) {
        presenter.postSupplied(post)
    }
    
    func getResultingPost() -> (post: Post, isNewPost: Bool) {
        return (post: presenter.resultingPost, isNewPost: presenter.isNewPost)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupTextFieldBottomLines()
        
        subredditField.delegate = self
        
        presenter.attachView(self)
        presenter.viewDidLoad()
    }
    
//    private func setupTextFieldBottomLines() {
//        let bottomLine = CALayer()
//        bottomLine.frame = CGRect(x: 0, y: titleField.frame.height - 2, width: titleField.layer.frame.width - 50, height: 2)
//        bottomLine.backgroundColor = view.tintColor.cgColor
//        titleField.layer.addSublayer(bottomLine)
//    }
    
    func indicateNewPost() {
        navigationItem.title = PostDetailViewController.TEXT_NEW_POST_TITLE
    }
    
    func pasteIntoUrl() {
        let clipboard = Helper.getClipboard()
        
        var newContent: String?
        if clipboard.hasURLs, let url = clipboard.url?.absoluteString {
            newContent = url
        } else if clipboard.hasStrings, let string = clipboard.string {
            newContent = string
        }
        
        if let newContent = newContent {
            contentField.text = newContent
            contentField.sendActions(for: .editingChanged)
        }
    }
    
    func displayPost(_ post: Post) {
        titleField.text = post.title
        datePicker.date = post.date
        subredditField.text = post.subreddit
        
        let content: String?
        let segmentIndex: Int
        switch post.type {
        case .text:
            content = post.text
            segmentIndex = 1
        case .link:
            content = post.url
            segmentIndex = 0
        }
        
        contentField.text = content
        typeControl.selectedSegmentIndex = segmentIndex
        
        updateContentField()
        updatePasteButton()
        updateSubredditPrefix()
    }
    
    private func updatePasteButton() {
        let clipboard = Helper.getClipboard()
        
        let linkPost = typeControl.selectedSegmentIndex == 0
        let clipboardHasSomething = clipboard.hasURLs || clipboard.hasStrings
        
        pasteButton.isHidden = !linkPost || !clipboardHasSomething
    }
    
    private func updateContentField() {
        let placeholder: String
        let spellCheckingType: UITextSpellCheckingType
        let keyboardType: UIKeyboardType
        
        switch typeControl.selectedSegmentIndex {
        case 0: // link
            placeholder = PostDetailViewController.TEXT_LINK_PLACEHOLDER
            spellCheckingType = .no
            keyboardType = .URL
        case 1: // text
            placeholder = PostDetailViewController.TEXT_SELF_PLACEHOLDER
            spellCheckingType = .default
            keyboardType = .default
        default:
            fatalError()
        }
        
        contentField.placeholder = placeholder
        contentField.spellCheckingType = spellCheckingType
        contentField.keyboardType = keyboardType
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            Log.p("this didnt work")
            return
        }
        
        presenter.saveButtonPressed()
    }
    
    func dismiss() {
        let animated = true
        
        let presentingInAddMode = presentingViewController is UINavigationController
        if presentingInAddMode {
            dismiss(animated: animated, completion: nil)
        } else if let owningNavigationController = navigationController {
            owningNavigationController.popViewController(animated: animated)
        } else {
            fatalError("The PostViewController is not inside a navigation controller")
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
    
    @IBAction func pasteButtonPressed(_ sender: Any) {
        pasteIntoUrl()
    }
    
    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        updateContentField()
        updatePasteButton()
        presenter.postTypeChanged()
    }
    
    @IBAction func titleChanged(_ sender: Any) {
        presenter.titleChanged()
    }
    
    @IBAction func contentChanged(_ sender: Any) {
        presenter.contentChanged()
    }
    
    @IBAction func subredditChanged(_ sender: Any) {
        updateSubredditPrefix()
        presenter.subredditChanged()
    }
    
    private func updateSubredditPrefix() {
        subredditPrefixLabel.isHidden = PostDetailViewController.emptyIfNull(subredditField.text).trim().isEmpty
    }
    
    private static func emptyIfNull(_ str: String?) -> String { // todo: extract into extensions
        return str ?? ""
    }
    
    // subredditField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let disallowed = PostDetailViewController.SUBREDDIT_ALLOWED_CHARACTERS.inverted
        let onlyContainsAllowed = string.rangeOfCharacter(from: disallowed) == nil
        
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        let goodLength = newString.count <= PostDetailViewController.MAX_SUBREDDIT_LENGTH
        
        return onlyContainsAllowed && goodLength
    }
}
