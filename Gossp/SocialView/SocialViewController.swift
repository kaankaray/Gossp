//
//  SocialViewController.swift
//  Gossp
//
//  Created by Kaan Karay on 10.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import QuartzCore
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseCore

class SocialViewController: UITableViewController {
  //@IBOutlet var navBar: UINavigationBar!
  @IBOutlet var navBar: UINavigationItem!
  
  override func viewWillAppear(_ animated: Bool) {
    navigationController?.navigationBar.barStyle = .black
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navBar.title = currentUser.name
    navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: currentUser.color()]
    
    // Listen to the color.
    DispatchQueue.global(qos: .background).async {
      _ = ref.child("users").child(currentUser.name).observe(DataEventType.value, with: { (snapshot) in
        DispatchQueue.main.async {
          let value = snapshot.value as? NSDictionary
          currentUser.colors = value?["colors"] as? Array<CGFloat> ?? [0,0,0]
          self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: currentUser.color()]
        }
      })
    }
    
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return 4
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {return 123}
  
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as! LocationsListCellTableViewCell
    // Configure the cell...
    
    return cell
  }
  override var preferredStatusBarStyle: UIStatusBarStyle {return .lightContent}
}
