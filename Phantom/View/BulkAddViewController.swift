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
        case bulkBackToList = "backBulkAdd"
    }
    
    @IBOutlet weak var postsView: UITextView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var postsText: String? {
        get { postsView.text }
        set { postsView.text = newValue }
    }
    
    private let presenter = BulkAddPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        postsView.becomeFirstResponder()
        
        postsView.delegate = self

        presenter.attachView(self)
        presenter.viewDidLoad()
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
        return identifier == BulkAddViewController.Segue.bulkBackToList.rawValue
            && presenter.shouldPerformAddSegue()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        presenter.textChanged()
    }
    
    func getResultingPosts() -> [BarePost]? {
        return presenter.posts
    }
    
    func getClipboard() -> String? { // todo: maybe refactor it into Helper or something
        return UIPasteboard.general.string
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
    
    @IBAction func textChanged(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
    
    @IBAction func pasteButtonPressed(_ sender: Any) {
        presenter.pasteButtonPressed()
    }
}
