//
//  ViewController.swift
//  example
//
//  Created by carlos on 18/5/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInFailureText: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var disposeBag = DisposeBag()
    var backgroundWorkScheduler: ImmediateScheduler!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = NSQualityOfService.UserInitiated
        backgroundWorkScheduler = OperationQueueScheduler(operationQueue: operationQueue)
        
        
        /* map function transform a sequence of a type in another sequence of diferent type */
        let validUsernameSignal /* : Observable<Bool> */ = usernameTextField.rx_text()
            // map Observable<String> to an Observable<Bool>
            >- map { text in
                self.isValidUsername(text)
        }
        
        let validPasswordSignal /* : Observable<Bool> */ = passwordTextField.rx_text()
            // map Observable<String> to an Observable<Bool>
            >- map { text in
                self.isValidPassword(text)
        }
        
        validUsernameSignal
            // map Observable<Bool> to an Observable<UIColor>
            >- map { isValid in
                isValid ? UIColor.clearColor() : UIColor.yellowColor()
            }
            >- subscribeNext { [unowned self] color in
                self.usernameTextField.backgroundColor = color
            }
        
        validPasswordSignal
            // map Observable<Bool> to an Observable<UIColor>
            >- map { isValid in
                isValid ? UIColor.clearColor() : UIColor.yellowColor()
            }
            >- subscribeNext { [unowned self] color in
                self.passwordTextField.backgroundColor = color
        }
        
        // you can combine multiples observable
        let signUpActiveSignal /*: Observable<Bool> */ = combineLatest(validUsernameSignal, validPasswordSignal) { isValidUserName, isValidPassword in
            return isValidUserName && isValidPassword
        }
        
        // suscribing to an combined observable
        signUpActiveSignal
            >- subscribeNext { [unowned self] valid in
                self.signInButton.enabled = valid
            }
            >- disposeBag.addDisposable
        // Note:
        // DisposeBag retains the disposable, otherwise it will attempt to retain a deallocated object (Test to run the a app commenting the line '>- disposeBag.addDisposable')
        // The previous disposable we could have assigned to an instance variable, but add this to save DisposeBag instance variables in case you have to hold several disposables
        // Moreover, DisposeBag has a `dispose()` method, which dispose all observable added to it
        
        
        
        // FIXME: This sequence only work on the first tap
        signInButton.rx_tap()
            >- doOnNext {
                self.signInButton.enabled = false
                self.signInFailureText.hidden = true
                self.activityIndicator.startAnimating()
            }
//            >- observeSingleOn(self.backgroundWorkScheduler)
            >- map {
                self.checkLogin(username: self.usernameTextField.text, password: self.passwordTextField.text)
            }
            >- concat
//            >- observeSingleOn(MainScheduler.sharedInstance) // TODO: This don't work
//            >- variable
            >- subscribeNext { valid in
                self.activityIndicator.stopAnimating()
                self.signInFailureText.hidden = valid
                self.signInButton.enabled = true
                if valid {
                    self.performSegueWithIdentifier("goToOtherVC", sender: self)
                    self.usernameTextField.text = ""
                    self.passwordTextField.text = ""
                    self.usernameTextField.backgroundColor = UIColor.yellowColor()
                    self.passwordTextField.backgroundColor = UIColor.yellowColor()
                    self.signInButton.enabled = false
                }
            }
            >- disposeBag.addDisposable
    }
    
    // MARK: - Validate string functions
    
    func isValidUsername(username: String) -> Bool {
        return count(username) > 3
    }
    
    func isValidPassword(password: String) -> Bool {
        return count(password) > 3
    }
    
    // MARK: - Create a custom Observable
    
    func checkLogin(#username: String, password: String) -> Observable<Bool> {
        
        return create { observer in
            let task = {
                DummyAsynchronousService().singInWithUserName(username, password: password) { success in
                    if success {
                        observer.on(Event.Next(Box(true)))
                    }
                    else {
                        observer.on(Event.Next(Box(false)))
                    }
                }
            }
            task()
            return AnonymousDisposable {
                // TODO: really need a dispose function?
            }
        }
        
    }
    
}


typealias ValidationObservable = Observable<(valid: Bool?, message: String?)>

class DummyAsynchronousService {
    
    func singInWithUserName(userName: String, password: String, callback: Bool -> Void) {
        
        delay(2.0) {
            let success = userName == "user" && password == "password"
            callback(success)
        }
        
    }
    
}


// global function which run the closusure after of `delay` seconds
// for the purpose of illustrating asynchronous execution
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}







