//
//  ViewController.swift
//  TouchIDDemo
//
//  Created by Gabriel Theodoropoulos on 8/25/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

import UIKit
import LocalAuthentication


class ViewController: UIViewController, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, EditNoteViewControllerDelegate {
    
    @IBOutlet weak var tblNotes: UITableView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    var dataArray: NSMutableArray!
    
    var noteIndexToEdit: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        tblNotes.delegate = self
        tblNotes.dataSource = self
        
        authenticateUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "idSegueEditNote"{
            var editNoteViewController : EditNoteViewController = segue.destinationViewController as EditNoteViewController
            
            editNoteViewController.delegate = self
            
            if (noteIndexToEdit != nil) {
                editNoteViewController.indexOfEditedNote = noteIndexToEdit
                
                noteIndexToEdit = nil
            }
        }
    }
    
    
    // MARK: Method implementation
    
    func authenticateUser() {
        // Get the local authentication context.
        let context = LAContext()
        
        // Declare a NSError variable.
        var error: NSError?
        
        // Set the reason string that will appear on the authentication alert.
        var reasonString = "Authentication is needed to access your notes."
        
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context .evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: NSError?) -> Void in
                
                if success {
                    // If authentication was successful then load the data.
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.loadData()
                    })
                }
                else{
                    // If authentication failed then show a message to the console with a short description.
                    // In case that the error is a user fallback, then show the password alert view.
                    println(evalPolicyError?.localizedDescription)
                    
                    switch evalPolicyError!.code {
                        
                    case LAError.SystemCancel.rawValue:
                        println("Authentication was cancelled by the system")
                        
                    case LAError.UserCancel.rawValue:
                        println("Authentication was cancelled by the user")
                        
                    case LAError.UserFallback.rawValue:
                        println("User selected to enter custom password")
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.showPasswordAlert()
                        })
                        
                        
                    default:
                        println("Authentication failed")
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.showPasswordAlert()
                        })
                    }
                }
                
            })]
        }
        else{
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            
            case LAError.TouchIDNotEnrolled.rawValue:
                println("TouchID is not enrolled")
                
            case LAError.PasscodeNotSet.rawValue:
                println("A passcode has not been set")
                
            default:
                // The LAError.TouchIDNotAvailable case.
                println("TouchID not available")
            }
            
            // Optionally the error description can be displayed on the console.
            println(error?.localizedDescription)
            
            // Show the custom alert view to allow users to enter the password.
            showPasswordAlert()
        }
    }

    
    func showPasswordAlert() {
        var passwordAlert : UIAlertView = UIAlertView(title: "TouchIDDemo", message: "Please type your password", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Okay")
        passwordAlert.alertViewStyle = UIAlertViewStyle.SecureTextInput
        passwordAlert.show()
    }
    
    
    func loadData(){
        if appDelegate.checkIfDataFileExists() {
            self.dataArray = NSMutableArray(contentsOfFile: appDelegate.getPathOfDataFile())
            self.tblNotes.reloadData()
        }
        else{
            println("File does not exist")
        }
    }
    
    
    // MARK: UIAlertViewDelegate method implementation
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            if !alertView.textFieldAtIndex(0)!.text.isEmpty {
                if alertView.textFieldAtIndex(0)!.text == "appcoda" {
                    loadData()
                }
                else{
                    showPasswordAlert()
                }
            }
            else{
                showPasswordAlert()
            }
        }
    }
    
    
    // MARK: TableView method implementation
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let array = dataArray {
            return array.count
        }
        else{
            return 0
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("idCell") as UITableViewCell
        
        let currentNote = self.dataArray.objectAtIndex(indexPath.row) as Dictionary<String, String>
        cell.textLabel!.text = currentNote["title"]
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        noteIndexToEdit = indexPath.row
        
        performSegueWithIdentifier("idSegueEditNote", sender: self)
    }
    
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete{
            // Delete the respective object from the dataArray array.
            dataArray.removeObjectAtIndex(indexPath.row)
            
            // Save the array to disk.
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            dataArray.writeToFile(appDelegate.getPathOfDataFile(), atomically: true)
            
            // Reload the tableview.
            tblNotes.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    
    
    // MARK: EditNoteViewControllerDelegate method implementation
    
    func noteWasSaved() {
        // Load the data and reload the table view.
        loadData()
    }
}

