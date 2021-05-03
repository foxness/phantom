//
//  BulkAddViewController.swift
//  Phantom
//
//  Created by River on 2021/05/03.
//  Copyright © 2021 Rivershy. All rights reserved.
//

import UIKit

class BulkAddViewController: UIViewController, BulkAddViewDelegate, UITextViewDelegate {
    static let SEGUE_BACK_BULK_TO_LIST = "backBulkAdd"
    
    @IBOutlet weak var postsView: UITextView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var postsText: String? { postsView.text }
    
    private let presenter = BulkAddPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        presenter.addButtonPressed()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        presenter.textChanged()
    }
    
    func getResultingPosts() -> [Post]? {
        return presenter.posts
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
    
    @IBAction func textChanged(_ sender: Any) {
        presenter.cancelButtonPressed()
    }
}
