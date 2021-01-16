//
//  ProfileViewController.swift
//  Mini
//
//  Created by Rishi Palivela on 16/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import UIKit
import FirebaseUI

class ProfileViewController: UITableViewController {
    var user: User?
    var authUI: FUIAuth!
    var authStateHandle: AuthStateDidChangeListenerHandle?
       
    private lazy var userURL: URL = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("User", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }()
    
    @IBOutlet weak var userDP: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.backgroundColor = .tableBackground
        authUI = (UIApplication.shared.delegate as! AppDelegate).authUI
        addAuthObserver()
        
        userDP.layer.cornerRadius = userDP.frame.width/2
        userDP.clipsToBounds = true
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAuthObserver()
    }
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.backgroundColor = .tableBackground
        view.tintColor = .tableBackground
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath)
        switch  cell?.textLabel?.text ?? "" {
        case "Show My Info":
            performSegue(withIdentifier: "Show Details", sender: self)
        
        case "Settings":
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            
        case "Sign Out":
            let alertController = UIAlertController(title: "Are you sure?",
                                                    message: "Do you want to sign out?",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Confirm", style: .destructive){ _ in
                try? self.authUI.signOut()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            self.present(alertController, animated: true)
            
        default:
            break
        }
    }
    
    @objc func addAuthObserver() {
        guard authStateHandle == nil else { return }
        print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
        
        authStateHandle = authUI.auth?.addStateDidChangeListener { [unowned self] (auth, user) in
            print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
            self.user = user
            self.reloadView()
            
        }
    }
    
    @objc func removeAuthObserver() {
       if let _ = authStateHandle {
           print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
           
           authUI.auth?.removeStateDidChangeListener(authStateHandle!)
           authStateHandle = nil
       }
    }
    
    func reloadView(){
        guard let user = user else {
            usernameLabel.text = "Username"
            userDP.image = UIImage(named: "profile")
            return
        }
        
        usernameLabel.text = user.displayName

        let dpURL = userURL.appendingPathComponent("\(user.uid).jpg")
        
        if FileManager.default.fileExists(atPath: dpURL.path) {
            userDP.image = UIImage(contentsOfFile: dpURL.path)
        } else if let userPhotoURL = user.photoURL {
           URLSession.shared.dataTask(with: userPhotoURL) { data, response, error in
               guard let data = data else {
                   print(error?.localizedDescription ?? "Unknown Error")
                   return
               }

               FileManager.default.createFile(atPath: dpURL.path, contents: data, attributes: nil)

               DispatchQueue.main.async {
                    self.userDP.image = UIImage(data: data)
               }
           }.resume()
        }
    }
}
