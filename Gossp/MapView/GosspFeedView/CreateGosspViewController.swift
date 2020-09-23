//
//  CreateGosspViewController.swift
//  Gossp
//
//  Created by Kaan Karay on 24.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import MobileCoreServices
import Tagging

class CreateGosspViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, TaggingDataSource, TagableListScrollViewDelegate {
  
  @IBOutlet var subjectTextField: UITextField!
  @IBOutlet var GosspButton: UIButton!
  @IBOutlet var mediaButton: UIButton!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var cancelButton: UIButton!
  @IBOutlet var whoCanCommentLabel: UILabel!
  @IBOutlet var allowedComments: UISegmentedControl!
  @IBOutlet var contextTagging: Tagging!
  @IBOutlet var taggableList: TagableListScrollView!
  
  var GosspToBe:Gossp = Gossp()
  var currentUser:GosspUser = GosspUser()
  var loc:GosspLocation = GosspLocation()
  var imagePicked = false
  
  @IBAction func cancelButtonAct(_ sender: Any) {
    imageView.image = UIImage(named: "addButtonImage.png")
    cancelButton.isHidden = true
    imagePicked = false
  }
  @IBAction func mediaButtonAct(_ sender: Any) {
    let picker = UIImagePickerController()
    picker.allowsEditing = true
    picker.delegate = self
    present(picker, animated: true)
  }
  @IBAction func GosspButtonAct(_ sender: Any) {
    GosspToBe.ID = loc.GosspArray.count
    GosspToBe.creator = currentUser
    GosspToBe.creationDate = Date().timeIntervalSince1970
    GosspToBe.upVotes = [currentUser]
    GosspToBe.downVotes = []
    GosspToBe.parentID = -2
    GosspToBe.subject = subjectTextField.text!
    GosspToBe.context = contextTagging.textView.text
    GosspToBe.comments = []
    
    let saveLocation = "locations/" + "value\(loc.ID)/" + "GosspArray/" + String(loc.GosspArray.last?.ID ?? 0)
    if imagePicked {uploadMedia(location: String(saveLocation) + ".png") { (url) in
      print("Photo saved at \(url!)")
      }}
    ref.child(saveLocation).setValue(GosspToBe.returnAsDictionary()){
      (error:Error?, ref:DatabaseReference) in
      if let error = error {
        print("Data could not be saved: \(error).")
      } else {
        print("Data saved successfully!")
        self.navigationController?.popViewController(animated: true)
      }
    }
  }
  @IBAction func subChanged(_ sender: Any) {
    if subjectTextField.text!.count < 3  {GosspButton.isHidden = true} else {
      if contextTagging.textView.text != "Enter the context here." && contextTagging.textView.text.count > 0 {GosspButton.isHidden = false}
    }
    self.title = subjectTextField.text
  }
  
  func uploadMedia(location:String, completion: @escaping (_ url: String?) -> Void) {
    let storageRef = Storage.storage().reference().child(location)
    if let uploadData = (self.imageView.image!).pngData() {
      storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
        if error != nil {
          print("error")
          completion(nil)
        } else {
          storageRef.downloadURL(completion: { (url, error) in
            print(url?.absoluteString ?? "url error at uploading for some reason")
            completion(url?.absoluteString)
          })
        }
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  /*
   @objc func keyboardWillShow(_ notification: Notification) {
   if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
   print(keyboardFrame.cgRectValue.height)
   DispatchQueue.main.async {
   let k = self.subjectTextField.frame
   self.subjectTextField.frame.size = CGSize(width: k.width, height: k.height - keyboardFrame.cgRectValue.height)
   //self.subjectTextField.frame = CGRect(x: k.origin.x, y: k.origin.y, width: k.width, height: k.height - keyboardFrame.cgRectValue.height)
   }
   
   }
   }*/
  
  override func viewWillAppear(_ animated: Bool) {
    view.backgroundColor = .gosspPurple
    subjectTextField.layer.borderWidth = 2
    subjectTextField.layer.borderColor = UIColor.white.cgColor
    subjectTextField.tintColor = .white
    subjectTextField.textColor = .white
    subjectTextField.attributedPlaceholder = NSAttributedString(string: "Subject",attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    subjectTextField.backgroundColor = .gosspLighterPurple
    
    subjectTextField.becomeFirstResponder()
    
    //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    mediaButton.tintColor = .gosspGreen
    mediaButton.layer.zPosition = 3
    
    GosspButton.tintColor = .gosspGreen
    GosspButton.isHidden = true
    
    cancelButton.isHidden = true
    
    allowedComments.backgroundColor = .gosspPurple
    allowedComments.setTitleTextAttributes([.foregroundColor: UIColor.gosspGreen], for: .normal)
    allowedComments.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    if #available(iOS 13.0, *) {allowedComments.selectedSegmentTintColor = .gosspGreen}
    else {allowedComments.tintColor = .gosspGreen}
    whoCanCommentLabel.textColor = .white
    
    
    contextTagging.dataSource = self
    contextTagging.textView.delegate = self
//    contextTagging.textView.text = "Enter the context here."
//    contextTagging.textView.textColor = .lightGray
    contextTagging.tintColor = .gosspGreen
    
    contextTagging.borderColor = UIColor.gosspGreen.cgColor
    contextTagging.borderWidth = 1.0
    contextTagging.cornerRadius = 20
    contextTagging.textInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    contextTagging.backgroundColor = .gosspPurple
    contextTagging.defaultAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.underlineStyle: NSNumber(value: 0)]
    contextTagging.defaultSymbolAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.underlineStyle: NSNumber(value: 1)]
    contextTagging.defaultTaggedAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.underlineStyle: NSNumber(value: 1)]
    
    
    var userListNames:Array<String> = []
    var userListColors:Array<UIColor> = []
    var userListDeleted:Array<Bool> = []
    loc.contCount.forEach {
      userListNames.append($0.name)
      userListColors.append($0.color())
      userListDeleted.append($0.isDeleted)
    }
    print(userListNames)
    contextTagging.tagableList = userListNames
    contextTagging.isHidden = false
    taggableList.delegate = self
    
  }
  
  func tagging(_ tagging: Tagging, didChangedTagableList tagableList: [String]) {
    var userListColors:Array<UIColor> = []
    var userListDeleted:Array<Bool> = []
    tagableList.forEach { (element) in
      loc.contCount.forEach {
        if element == $0.name{
          userListColors.append($0.color())
          userListDeleted.append($0.isDeleted)
        }
      }
    }
    taggableList.list = tagableList
    taggableList.listColors = userListColors
    taggableList.listDeleted = userListDeleted
    taggableList.drawButtons()
  }
  
  func tagging(_ tagging: Tagging, didChangedTaggedList taggedList: [TaggingModel]) {
    //self.taggedList = taggedList
//    print(taggedList)
  }
  
  func predictionSelected(_ sender: TagableListScrollView, withNumber: Int) {
    contextTagging.updateTaggedList(allText: contextTagging.textView.text, tagText: sender.list[withNumber],
                                    tagAttribute: [NSAttributedString.Key.foregroundColor: sender.listColors[withNumber], NSAttributedString.Key.underlineStyle: NSNumber(value: 1)],
                                    symbolAttribute: [NSAttributedString.Key.foregroundColor: sender.listColors[withNumber], NSAttributedString.Key.underlineStyle: NSNumber(value: 1)])
    taggableList.butList.forEach{$0.removeFromSuperview()}
    
  }
  
  
  
  //MARK: UIImagePickerDelegate
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let image = info[.editedImage] as? UIImage else { return }
    
    //let imageName = UUID().uuidString
    //let imagePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(imageName)
    imageView.image = image
    cancelButton.isHidden = false
    imagePicked = true
    
    dismiss(animated: true)
  }
  
  
  
  //MARK: TextViewDelegate
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.textColor == UIColor.lightGray {
      textView.text = nil
    }
  }
  
  func textViewDidChange(_ textView: UITextView) {
    if textView.text == "Enter the context here." || textView.text.count < 1{GosspButton.isHidden = true}
    else {if !(subjectTextField.text!.count < 3) {GosspButton.isHidden = false}}
    contextTagging.textViewDidChange(textView)
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.isEmpty {
      textView.text = "Enter the context here."
      textView.textColor = UIColor.lightGray
      GosspButton.isHidden = true
    }
  }
  func textViewDidChangeSelection(_ textView: UITextView) {contextTagging.textViewDidChangeSelection(textView)}
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    return contextTagging.textView(textView, shouldChangeTextIn: range, replacementText: text)
    
  }
  
}
