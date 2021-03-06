//
//  CreateAliasViewController.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 12/01/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import UIKit
import Toaster
import MBProgressHUD
import SkyFloatingLabelTextField

final class CreateAliasViewController: BaseApiKeyViewController {
    @IBOutlet private weak var rootStackView: UIStackView!
    @IBOutlet private weak var prefixTextField: UITextField!
    @IBOutlet private weak var suffixView: UIView!
    @IBOutlet private weak var suffixLabel: UILabel!
    @IBOutlet private weak var noteTextField: SkyFloatingLabelTextField!
    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var warningLabel: UILabel!
    @IBOutlet private weak var createButton: UIButton!
    
    private var isValidEmailPrefix: Bool = false {
        didSet {
            createButton.isEnabled = isValidEmailPrefix
            createButton.alpha = isValidEmailPrefix ? 1 : 0.3
            prefixTextField.textColor = isValidEmailPrefix ? SLColor.textColor : SLColor.negativeColor
        }
    }
    
    private var userOptions: UserOptions? {
        didSet {
            suffixLabel.text = userOptions?.suffixes[0]
            alertUpgradeIfApplicable()
        }
    }
    
    private var selectedSuffixIndex = 0 {
        didSet {
            suffixLabel.text = userOptions?.suffixes[selectedSuffixIndex]
        }
    }
    
    var showPremiumFeatures: (() -> Void)?
    var createdAlias: ((_ alias: Alias) -> Void)?
    var didDisappear: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prefixTextField.becomeFirstResponder()
        isValidEmailPrefix = false
        setUpUI()
        fetchUserOptions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didDisappear?()
    }
    
    private func setUpUI() {
        prefixTextField.textColor = SLColor.textColor
        prefixTextField.delegate = self
        
        // suffixView
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentSuffixListViewController))
        suffixView.isUserInteractionEnabled = true
        suffixView.addGestureRecognizer(tap)
        
        createButton.setTitleColor(SLColor.tintColor, for: .normal)
        
        hintLabel.textColor = SLColor.secondaryTitleColor
        warningLabel.textColor = SLColor.negativeColor
    }
    
    private func fetchUserOptions() {
        MBProgressHUD.showAdded(to: view, animated: true)
        rootStackView.isHidden = true
        
        SLApiService.fetchUserOptions(apiKey: apiKey) { [weak self] result in
            guard let self = self else { return }
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch result {
            case .success(let userOptions):
                self.rootStackView.isHidden = false
                self.userOptions = userOptions
                
            case .failure(let error):
                Toast.displayError(error)
            }
        }
    }
    
    private func createAlias() {
        guard let suffix = userOptions?.suffixes[selectedSuffixIndex] else {
            Toast.displayShortly(message: "No suffix is selected")
            return
        }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        SLApiService.createAlias(apiKey: apiKey, prefix: prefixTextField.text ?? "", suffix: suffix, note: noteTextField.text) { [weak self] result in
            guard let self = self else { return }
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch result {
            case .success(let newlyCreatedAlias):
                self.createdAlias?(newlyCreatedAlias)
                self.dismiss(animated: true, completion: nil)
                
            case .failure(let error):
                Toast.displayError(error)
            }
        }
    }
    
    @IBAction private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func createButtonTapped() {
        createAlias()
    }
    
    @IBAction private func prefixTextFieldEditingChanged() {
        guard let text = prefixTextField.text else { return }
        isValidEmailPrefix = text.isValidEmailPrefix()
    }
    
    @objc private func presentSuffixListViewController() {
        performSegue(withIdentifier: "showSuffixes", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let suffixListViewController as SuffixListViewController:
            suffixListViewController.selectedSuffixIndex = selectedSuffixIndex
            suffixListViewController.suffixes = userOptions?.suffixes
            suffixListViewController.delegate = self
            
        default: return
        }
    }
    
    private func alertUpgradeIfApplicable() {
        guard let userOptions = userOptions, !userOptions.canCreate else { return }
        
        let alert = UIAlertController(title: "Upgrade needed", message: "You have reached the limit. Please upgrade to premium for unlimited aliases and more useful features.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Show me premium features", style: .default) { [unowned self] _ in
            self.dismiss(animated: true) {
                self.showPremiumFeatures?()
            }
        }
        alert.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Not right now", style: .cancel) { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - SuffixListViewControllerDelegate
extension CreateAliasViewController: SuffixListViewControllerDelegate {
    func didSelectSuffix(atIndex index: Int) {
        selectedSuffixIndex = index
    }
}

// MARK: - UITextFieldDelegate
extension CreateAliasViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        createAlias()
        return true
    }
}
