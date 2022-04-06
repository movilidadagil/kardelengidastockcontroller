//
//  StockRecorderViewController.swift
//  AnyVcNavigator
//
//  Created by Hasan Hüseyin Ali Gül on 3.04.2022.
//  Copyright © 2022 Arjun Baru. All rights reserved.
//

import AVFoundation
import Vision
import UIKit
import SQLite
import FirebaseFirestore

class StockRecorderViewController : UIViewController, AVCapturePhotoCaptureDelegate {
    
    let backButton = UIBarButtonItem()

     
    var row_id = ""
    var db: Connection?
    let productBarcode = ""
    let productName = ""
    let productCount = ""
    let productPrice =  ""
    let tblKardelen = Table("kardelenPRD")
    let dbProductBarcode = Expression<String>("productBarcode")
    let dbProductName = Expression<String>("productName")
    let dbProductCount = Expression<Double>("productCount")
    let dbProductPrice = Expression<Double>("productPrice")
    
    var productArray=[Product]()
    
    let txtProductName : CustomTextField = {
        let txt = CustomTextField(padding:15)
        txt.backgroundColor = .white
        txt.placeholder = "Ürün İsmi"
        txt.keyboardType = .alphabet
        //txt.addTarget(self, action: #selector(catchTextFieldChange), for: .editingChanged)
        txt.isHidden = true

        return txt
    }()
    
    
    
    let txtProductCount : CustomTextField = {
        let txt = CustomTextField(padding:15)
        txt.backgroundColor = .white
        txt.placeholder = "Ürün Adet"
        txt.keyboardType = .alphabet
        //txt.addTarget(self, action: #selector(catchTextFieldChange), for: .editingChanged)
        txt.isHidden = true

        return txt
    }()
    
    
    let txtProductPrice : CustomTextField = {
        let txt = CustomTextField(padding:15)
        txt.backgroundColor = .white
        txt.placeholder = "Ürün Fiyat"
        txt.keyboardType = .alphabet
        //txt.addTarget(self, action: #selector(catchTextFieldChange), for: .editingChanged)
        txt.isHidden = true

        return txt
    }()
    
    
    let btnStockReader : UIButton = {
        
        let btn = UIButton(type: .system)
        btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        btn.layer.cornerRadius = 22
        btn.setTitle("Ürünü Okut", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
        btn.backgroundColor = .lightGray
        btn.setTitleColor(.darkGray, for: .disabled)
        btn.isEnabled = true
        btn.addTarget(self, action: #selector(btnStockReaderPressed), for: .touchUpInside)
        return btn
    }()
    
    let btnStockRecorder : UIButton = {
        
        let btn = UIButton(type: .system)
        btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        btn.layer.cornerRadius = 22
        btn.setTitle("Ürünü Kaydet", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
        btn.backgroundColor = .lightGray
        btn.setTitleColor(.darkGray, for: .disabled)
        btn.isEnabled = true
        btn.isHidden = true
        btn.addTarget(self, action: #selector(btnStockRecorderPressed), for: .touchUpInside)
        return btn
    }()
    lazy var verticalStackView : UIStackView = {
        
        let vSv = UIStackView(arrangedSubviews: [
    
            
            txtProductBarcode,
            txtProductName,
            txtProductCount,
            txtProductPrice,
            btnStockRecorder,
            btnStockReader
         
        ])
        vSv.axis = .vertical
        vSv.distribution = .fillEqually
        vSv.spacing = 10
        
        return vSv
    }()
    lazy var stockStackView = UIStackView(arrangedSubviews: [
                                                               verticalStackView
                                                              
                                                             ])
    fileprivate func setLayout(){
        
        view.addSubview(stockStackView)
        stockStackView.axis = .vertical
        stockStackView.spacing = 10
        _ = stockStackView.anchor(top: nil, bottom: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor
                                   ,padding: .init(top: 0, left: 45, bottom: 0, right: 45))
        stockStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    let txtProductBarcode: CustomTextField = {
        let txt = CustomTextField(padding:15)
        txt.backgroundColor = .white
        txt.placeholder = "Ürün Barkodu"
        txt.keyboardType = .alphabet
        //txt.addTarget(self, action: #selector(catchTextFieldChange), for: .editingChanged)
        
        return txt
    }()
    
    
    @objc fileprivate func btnStockReaderPressed(){
        print("btnstoc reader  is clicked")
        setupCameraLiveView()
        addShutterButton()
        btnStockReader.isHidden = true
        dbSetup()
    }
    fileprivate func stockInfoRecordToFireStore(productBarcode : String,
                                                productName : String,
                                                productCount : String,
                                                productPrice : String,
                                                completion : @escaping (Error?) -> ()){
        let insertionData = ["ProductName": productName ?? "",
                            "ProductCount": productCount ?? "",
                            "ProductPrice": productPrice ?? "",
                            "ProductBarcode":  productBarcode ?? "",
                             "ProductId": row_id ?? ""]
        
        Firestore.firestore().collection("Products").document(productBarcode+"-"+row_id).setData(insertionData) {
            (error) in
            if let error = error {
                completion(error)
                return
            }
            
        }
        
    }
    
    fileprivate func createNotificationObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(catchKeyboardView(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(catchKeyboardHideView(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc fileprivate func catchKeyboardHideView(notification:Notification){
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.transform = .identity
        }, completion: nil)
    }
    
    @objc fileprivate func catchKeyboardView(notification:Notification){
        // print(notification.userInfo)
        
        guard let keyboardEndValues = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardEndFrame = keyboardEndValues.cgRectValue
        
        print(keyboardEndFrame)
        print("\(keyboardEndFrame.width) - \(keyboardEndFrame.height)")
        
        guard let keyboardStartValues = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else {
            return
        }
        let keyboardStartFrame = keyboardStartValues.cgRectValue
        
        print(keyboardStartFrame)
        print("\(keyboardStartFrame.width) - \(keyboardStartFrame.height)")
        
        let bottomSpaceAmount = view.frame.height - (stockStackView.frame.origin.y + stockStackView.frame.height)
        
        print(bottomSpaceAmount)
        
        let faultRate = keyboardEndFrame.height - bottomSpaceAmount
        print(faultRate)
        self.view.transform = CGAffineTransform(translationX: 0, y: -faultRate)
    }
    fileprivate func addTapGesture(){
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(keyboardClose)))
    }
    @objc fileprivate func keyboardClose(){
        self.view.endEditing(true)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.transform = .identity
        }, completion: nil)
    }
    
    @objc fileprivate func btnStockRecorderPressed(completion : @escaping (Error?) ->()){
        print("btnstock recorder  is clicked")
        self.keyboardClose()
        guard let productBarcode = txtProductBarcode.text else {return }
        guard let productName = txtProductName.text else {return }
        guard let productCount = txtProductCount.text else {return}
        guard let productPrice = txtProductPrice.text else {return }
        
        print(txtProductBarcode.text)
        print(txtProductName.text)
        print(txtProductCount.text)
        print(txtProductPrice.text)

        
        do {
            let insert = self.tblKardelen.insert(dbProductBarcode <- productBarcode, dbProductName <- productName, dbProductCount <- Expression<Double>(productCount),
            dbProductPrice <- Expression<Double>(productPrice))
            let rowid = try db!.run(insert)
            row_id = String(rowid)
            print("Row inserted successfully id: \(rowid)")
            self.stockInfoRecordToFireStore(productBarcode: productBarcode,
                                            productName: productName,
                                            productCount: productCount,
                                            productPrice: productPrice,
                                            completion: completion)

           showAlert(self)
          
            
        } catch {
            print("insertion failed: \(error)")
                self.showAlert(withTitle: "Kaydedilirken hata oluştu tekrar deneyiniz ", message: "HATA!!!")
           

        }
    }
    
    @IBAction func showAlert(_ sender: Any) {
        let alertController = UIAlertController(title: "KARDELEN GIDA", message: "ÜRÜN BAŞARILI ŞEKİLDE KAYDEDİLDİ", preferredStyle: .alert)

        let acceptAction = UIAlertAction(title: "OK", style: .default) { (_) -> Void in

           // self.performSegue(withIdentifier: "SomeSegue", sender: self) // Replace SomeSegue with your segue identifier (name)
            let stockRecorderView = StockRecorderViewController()
            self.present(stockRecorderView, animated: true)
         
            self.verticalStackView.isHidden = true
        }

        alertController.addAction(acceptAction)

        present(alertController, animated: true, completion: nil)
        
    }
    
    var captureSession: AVCaptureSession!
    var backCamera: AVCaptureDevice?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureOutput: AVCapturePhotoOutput?

    var shutterButton: UIButton!

    var productCatalog = ProductCatalog()

    lazy var detectBarcodeRequest: VNDetectBarcodesRequest = {
        return VNDetectBarcodesRequest(completionHandler: { (request, error) in
            guard error == nil else {
                self.showAlert(withTitle: "Barcode Error", message: error!.localizedDescription)
                return
            }

            self.processClassification(for: request)
        })
    }()

    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        checkPermissions()
        //setupCameraLiveView()
        //addShutterButton()
        setLayout()
        addTapGesture()

    }

    override func viewDidAppear(_ animated: Bool) {
        // Every time the user re-enters the app, we must be sure we have access to the camera.
        checkPermissions()
    }

    // MARK: - User interface
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Camera
    private func checkPermissions() {
        let mediaType = AVMediaType.video
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)

        switch status {
        case .denied, .restricted:
            displayNotAuthorizedUI()
        case.notDetermined:
            // Prompt the user for access.
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                guard granted != true else { return }

                // The UI must be updated on the main thread.
                DispatchQueue.main.async {
                    self.displayNotAuthorizedUI()
                }
            }

        default: break
        }
    }
    
    private func stopCameraLiveView(){
        captureSession.stopRunning()
    }

    private func setupCameraLiveView() {
        // Set up the camera session.
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1280x720

        // Set up the video device.
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: .back)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
        }

        // Make sure the actually is a back camera on this particular iPhone.
        guard let backCamera = backCamera else {
            showAlert(withTitle: "Camera error", message: "There seems to be no camera on your device.")
            return
        }

        // Set up the input and output stream.
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(captureDeviceInput)
        } catch {
            showAlert(withTitle: "Camera error", message: "Your camera can't be used as an input device.")
            return
        }

        // Initialize the capture output and add it to the session.
        captureOutput = AVCapturePhotoOutput()
        captureOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        captureSession.addOutput(captureOutput!)

        // Add a preview layer.
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer!.videoGravity = .resizeAspectFill
        cameraPreviewLayer!.connection?.videoOrientation = .portrait
        cameraPreviewLayer?.frame = view.frame

        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)

        // Start the capture session.
        captureSession.startRunning()
    }

    @objc func captureImage() {
        let settings = AVCapturePhotoSettings()
        captureOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
            let image = UIImage(data: imageData) {

            // Convert image to CIImage.
            guard let ciImage = CIImage(image: image) else {
                fatalError("Unable to create \(CIImage.self) from \(image).")
            }

            // Perform the classification request on a background thread.
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation.up, options: [:])

                do {
                    try handler.perform([self.detectBarcodeRequest])
                } catch {
                    self.showAlert(withTitle: "Error Decoding Barcode", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - User interface
    private func displayNotAuthorizedUI() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.8, height: 20))
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = "Please grant access to the camera for scanning barcodes."
        label.sizeToFit()

        let button = UIButton(frame: CGRect(x: 0, y: label.frame.height + 8, width: view.frame.width * 0.8, height: 35))
        button.layer.cornerRadius = 10
        button.setTitle("Grant Access", for: .normal)
        button.backgroundColor = UIColor(displayP3Red: 4.0/255.0, green: 92.0/255.0, blue: 198.0/255.0, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let containerView = UIView(frame: CGRect(
            x: view.frame.width * 0.1,
            y: (view.frame.height - label.frame.height + 8 + button.frame.height) / 2,
            width: view.frame.width * 0.8,
            height: label.frame.height + 8 + button.frame.height
            )
        )
        containerView.addSubview(label)
        containerView.addSubview(button)
        view.addSubview(containerView)
    }

    private func addShutterButton() {
        let width: CGFloat = 75
        let height = width
        shutterButton = UIButton(frame: CGRect(x: (view.frame.width - width) / 2,
                                               y: view.frame.height - height - 32,
                                               width: width,
                                               height: height
            )
        )
        shutterButton.layer.cornerRadius = width / 2
        shutterButton.backgroundColor = UIColor.init(displayP3Red: 1, green: 1, blue: 1, alpha: 0.8)
        shutterButton.showsTouchWhenHighlighted = true
        shutterButton.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
        view.addSubview(shutterButton)
    }
    
    func dbSetup()
    {
        let databaseFileName = "db.sqlite3"
        let databaseFilePath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(databaseFileName)"
        db = try! Connection(databaseFilePath)

        
        try! db!.run(tblKardelen.create(ifNotExists: true) { t in
            t.column(dbProductBarcode)
            t.column(dbProductName)
            t.column(dbProductCount)
            t.column(dbProductPrice)
        })
    }
    

    private func showInfo(for payload: String) {
        if let product = productCatalog.item(forKey: payload) {
            print(payload)
            showAlert(withTitle: product.productName ?? "No product name provided", message: payload)
        } else {
            print("No item found for this payload " + payload)
            showAlert(withTitle: "Ürün barkodu yerleştiriliyor: " + payload, message: "")
            txtProductBarcode.text = payload
            txtProductName.isHidden = false
            txtProductCount.isHidden = false
            txtProductPrice.isHidden = false
            btnStockRecorder.isHidden = false
            stopCameraLiveView()
            

            
        }
    }

    // MARK: - Vision
    func processClassification(for request: VNRequest) {
        DispatchQueue.main.async {
            if let bestResult = request.results?.first as? VNBarcodeObservation,
                let payload = bestResult.payloadStringValue {
                self.showInfo(for: payload)
            } else {
                self.showAlert(withTitle: "Unable to extract results",
                               message: " Tekrar deneyiniz")
            }
        }
    }

    // MARK: - Helper functions
    @objc private func openSettings() {
        let settingsURL = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(settingsURL) { _ in
            self.checkPermissions()
        }
    }

    private func showAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}
