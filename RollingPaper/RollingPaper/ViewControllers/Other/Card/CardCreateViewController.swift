//
//  CardCreateViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/05.
//

import AVFoundation
import Combine
import PencilKit
import Photos
import StickerView
import SnapKit
import UIKit

class CardCreateViewController: UIViewController, UINavigationControllerDelegate, PKCanvasViewDelegate, PKToolPickerObserver {
    
    private let arrStickers: [String]
    private let backgroundImageName: [String]
    private let viewModel: CardViewModel
    private let toolPicker = PKToolPicker()
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var backgroundImg: UIImage?
    private var isCanvasToolToggle: Bool = true
    private var isStickerToggle: Bool = false
    private var isBackgroundToggle: Bool = false
    private var imageSticker: UIImage!
    private var _selectedStickerView: StickerView?
    private var selectedStickerView: StickerView? {
        get {
            return _selectedStickerView
        }
        set {
            // if other sticker choosed then resign the handler
            if _selectedStickerView != newValue {
                if let selectedStickerView = _selectedStickerView {
                    selectedStickerView.showEditingHandlers = false
                }
                _selectedStickerView = newValue
            }
            // assign handler to new sticker added
            if let selectedStickerView = _selectedStickerView {
                selectedStickerView.showEditingHandlers = true
                selectedStickerView.superview?.bringSubviewToFront(selectedStickerView)
            }
        }
    }
    
    private let imageShadowView: UIView = {
        let aView = UIView()
        aView.layer.shadowOffset = CGSize(width: 3, height: 3)
        aView.layer.shadowOpacity = 0.2
        aView.layer.shadowRadius = 30.0
        aView.backgroundColor = .systemBackground
        aView.layer.cornerRadius = 60
        aView.layer.shadowColor = UIColor.black.cgColor
        aView.translatesAutoresizingMaskIntoConstraints = false
        return aView
    }()
    
    lazy var rootUIImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.isUserInteractionEnabled = true
        return theImageView
    }()
    
    lazy var canvasView: PKCanvasView = {
        let canvas = PKCanvasView(frame: .zero)
        canvas.delegate = self
        canvas.layer.masksToBounds = true
        canvas.layer.cornerRadius = 32
        canvas.contentMode = .scaleAspectFill
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = true
        canvas.drawingPolicy = .anyInput
        canvas.translatesAutoresizingMaskIntoConstraints = true
        canvas.becomeFirstResponder()
        return canvas
    }()
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.layer.masksToBounds = true
        theImageView.layer.cornerRadius = 32
        theImageView.contentMode = .scaleAspectFill
        theImageView.image = backgroundImg
        return theImageView
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 100)
        layout.itemSize = CGSize(width: 100, height: 80)
        layout.scrollDirection = .horizontal
        
        let setCollectionView: UICollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        setCollectionView.dataSource = self
        setCollectionView.delegate = self
        setCollectionView.register(StickerCollectionViewCell.self, forCellWithReuseIdentifier: "StickerCollectionViewCell")
        setCollectionView.backgroundColor = .systemBackground
        setCollectionView.showsHorizontalScrollIndicator = false
        setCollectionView.translatesAutoresizingMaskIntoConstraints = false
        setCollectionView.layer.masksToBounds = true
        setCollectionView.layer.cornerRadius = 60
        
        return setCollectionView
    }()
    
    lazy var buttonLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemBackground
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 30
        label.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return label
    }()
    
    lazy var introWordingLabel: UILabel = {
        let label = UILabel()
        label.text = "사진 또는 배경을 넣어 주세요."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30)
        label.textColor = .lightGray
        return label
    }()
    
    lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "camera.fill")
        button.tintColor = UIColor(red: 217, green: 217, blue: 217)
        button.addTarget(self, action: #selector(importImage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var backgroundOnButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "paintpalette.fill")
        button.tintColor = .black
        button.addTarget(self, action: #selector(setPopOverView(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var backgroundOffButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "paintpalette.fill")
        button.tintColor = UIColor(red: 217, green: 217, blue: 217)
        button.addTarget(self, action: #selector(setPopOverView(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var divider: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 217, green: 217, blue: 217)
        return label
    }()
    
    lazy var pencilOnButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = .black
        button.addTarget(self, action: #selector(togglebutton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var pencilOffButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = UIColor(red: 217, green: 217, blue: 217)
        button.addTarget(self, action: #selector(togglebutton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var stickerOnButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "StickerToogleOn"), for: .normal)
        button.setImage(UIImage(named: "StickerToogleOn"), for: .highlighted)
        button.addTarget(self, action: #selector(togglebutton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var stickerOffButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "StickerToogleOff"), for: .normal)
        button.setImage(UIImage(named: "StickerToogleOff"), for: .highlighted)
        button.addTarget(self, action: #selector(togglebutton(_:)), for: .touchUpInside)
        return button
    }()
    
    init(viewModel: CardViewModel, arrStickers: [String], backgroundImageName: [String]) {
        self.viewModel = viewModel
        self.arrStickers = arrStickers
        self.backgroundImageName = backgroundImageName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        view.addSubview(introWordingLabel)
        introWordingLabelConstraints()
        
        view.addSubview(rootUIImageView)
        rootUIImageViewConstraints()
        
        rootUIImageView.addSubview(someImageView)
        someImageViewConstraints()
        
        rootUIImageView.addSubview(canvasView)
        canvasViewConstraints()
        
        view.addSubview(buttonLabel)
        buttonLabelConstraints()
        
        cameraButtonAppear()
        backgroundOffButtonAppear()
        
        dividerAppear()
        
        pencilButtonOn()
        canvasViewInteractionEnabled()
        toolPickerAppear()
        
        stickerButtonOff()
        stickerCollectionViewDisappear()
        
        checkCameraPermission()
        checkAlbumPermission()
        
        input.send(.viewDidLoad)
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentCardBackgroundImgSuccess(let background):
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "\(background ?? "Rectangle")")
                        print("get background ImgSuccess")
                    })
                case .getRecentCardBackgroundImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "Rectangle")
                    })
                case .getRecentCardResultImgSuccess(_):
                    DispatchQueue.main.async(execute: {
                        
                    })
                case .getRecentCardResultImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "Rectangle")
                        print("getRecentCardResultImgFail")
                    })
                }
            })
            .store(in: &cancellables)
    }
    
    func resultImageSend() {
        self.selectedStickerView?.showEditingHandlers = false
        guard let image = self.mergeImages(imageView: self.rootUIImageView) else { return }
        self.input.send(.setCardResultImg(result: image))
    }
    
    private func canvasViewInteractionDisabled() {
        rootUIImageView.addSubview(someImageView)
        someImageView.isUserInteractionEnabled = true
        someImageViewConstraints()
        
        rootUIImageView.addSubview(canvasView)
        canvasView.isUserInteractionEnabled = false
        canvasViewConstraints()
    }
    
    private func canvasViewInteractionEnabled() {
        rootUIImageView.addSubview(someImageView)
        someImageViewConstraints()
        
        rootUIImageView.addSubview(canvasView)
        canvasView.isUserInteractionEnabled = true
        canvasViewConstraints()
    }
    
    private func toolPickerAppear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
    }
    
    private func toolPickerDisappear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
    }
    
    private func cameraButtonAppear() {
        view.addSubview(cameraButton)
        cameraButtonConstraints()
    }
    
    private func backgroundOnButtonAppear() {
        view.addSubview(backgroundOnButton)
        backgroundOnButtonConstraints()
    }
    
    private func backgroundOffButtonAppear() {
        view.addSubview(backgroundOffButton)
        backgroundOffButtonConstraints()
    }
    
    private func dividerAppear() {
        view.addSubview(divider)
        dividerConstraints()
    }
    
    private func pencilButtonOn() {
        view.addSubview(pencilOnButton)
        pencilOnButtonConstraints()
    }
    
    private func pencilButtonOff() {
        view.addSubview(pencilOffButton)
        pencilOffButtonConstraints()
    }
    
    private func stickerButtonOn() {
        view.addSubview(stickerOnButton)
        stickerOnButtonConstraints()
    }
    
    private func stickerButtonOff() {
        view.addSubview(stickerOffButton)
        stickerOffButtonConstraints()
    }
    
    private func stickerCollectionViewAppear() {
        view.addSubview(imageShadowView)
        imageShadowViewConstraints()
        imageShadowView.animateShowingUP()
        
        view.addSubview(collectionView)
        collectionViewConstraints()
        collectionView.animateShowingUP()
    }
    
    private func stickerCollectionViewDisappear() {
        view.addSubview(imageShadowView)
        imageShadowView.isHidden = true
        imageShadowViewConstraints()
        
        view.addSubview(collectionView)
        collectionView.isHidden = true
        collectionViewConstraints()
    }
    
    @objc func setPopOverView(_ sender: UIButton) {
        isBackgroundToggle = true
        backgroundOnButtonAppear()
        
        let controller = BackgroundButtonViewController(viewModel: viewModel, backgroundImageName: backgroundImageName)
        controller.modalPresentationStyle = UIModalPresentationStyle.popover
        controller.preferredContentSize = CGSize(width: 128, height: 400)
        controller.presentationController?.delegate = self
        let popover = controller.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = CGRect(x: 25, y: 0, width: 50, height: 50)
        present(controller, animated: true)
    }
    
    @objc func togglebutton(_ gesture: UITapGestureRecognizer) {
        self.isCanvasToolToggle.toggle()
        self.isStickerToggle.toggle()
        if isCanvasToolToggle == true && isStickerToggle == false {
            print("sticker button off")
            stickerButtonOff()
            selectedStickerView?.showEditingHandlers = false
            stickerCollectionViewDisappear()
    
            pencilButtonOn()
            toolPickerAppear()
      
            canvasViewInteractionEnabled()
        } else {
            print("sticker button On")
            stickerButtonOn()
            stickerCollectionViewAppear()
            pencilButtonOff()
            toolPickerDisappear()
    
            canvasViewInteractionDisabled()
        }
    }
}

extension CardCreateViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        isBackgroundToggle = false
        backgroundOffButtonAppear()
        print("Modal Dismissed!")
    }
}

extension CardCreateViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func mergeImages(imageView: UIImageView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0.0)
        imageView.superview!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let renderer = UIGraphicsImageRenderer(size: imageView.frame.size)
        let image = renderer.image(actions: { _ in
            imageView.drawHierarchy(in: imageView.bounds, afterScreenUpdates: true)
        })
        UIGraphicsEndImageContext()
        return image
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrStickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let aCell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionViewCell", for: indexPath) as? StickerCollectionViewCell else {return UICollectionViewCell()}
        
        let image = UIImage(named: self.arrStickers[indexPath.item])
        let targetSize = CGSize(width: 80, height: 80)

        let scaledImage = image?.scalePreservingAspectRatio(targetSize: targetSize)
        aCell.myImage.image = scaledImage
        
        return aCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Click Collection cell \(indexPath.item)")
        if let cell = collectionView.cellForItem(at: indexPath) as? StickerCollectionViewCell {
            if let imageSticker = cell.myImage.image {
                let testImage = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
                testImage.image = imageSticker
                testImage.contentMode = .scaleAspectFit
                let stickerView = StickerView.init(contentView: testImage)
                stickerView.center = CGPoint.init(x: 400, y: 250)
                stickerView.delegate = self
                stickerView.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
                stickerView.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
                stickerView.setImage(UIImage.init(named: "Flip")!, forHandler: StickerViewHandler.flip)
                stickerView.showEditingHandlers = false
                stickerView.tag = 999
                self.someImageView.addSubview(stickerView)
                self.selectedStickerView = stickerView
            } else {
                print("Sticker not loaded")
            }
        }
    }
}

extension CardCreateViewController: StickerViewDelegate {
    func stickerViewDidTap(_ stickerView: StickerView) {
        self.selectedStickerView = stickerView
    }
    
    func stickerViewDidBeginMoving(_ stickerView: StickerView) {
        self.selectedStickerView = stickerView
    }
    
    func stickerViewDidChangeMoving(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidEndMoving(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidBeginRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidChangeRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidEndRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidClose(_ stickerView: StickerView) {
        
    }
}

extension UIButton {
    func setUIImage(systemName: String) {
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        imageView?.contentMode = .scaleAspectFit
        setImage(UIImage(systemName: systemName), for: .normal)
    }
}

extension UIView {
    func fadeOut(duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in }) {
        self.alpha = 1.0
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.transitionFlipFromBottom, animations: {
            self.isHidden = true
            self.alpha = 0.0
        }, completion: completion)
    }
    
    func animateShowingUP() {
        UIView.animateKeyframes(withDuration: 0.7, delay: 0) { [weak self] in
            guard let height = self?.bounds.height else {
                return
            }
            self?.alpha = 1
            self?.center.y = -height/4
            self?.isHidden = false
        }
    }
}

extension CardCreateViewController: UIImagePickerControllerDelegate {
    
    private func libraryImagePicker(withType type: UIImagePickerController.SourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = type
        present(pickerController, animated: true)
    }
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            if granted {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
            }
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            someImageView.image = pickedImage
        }
        picker.dismiss(animated: true)
    }
    
    private func cameraImagePicker() {
        let pushVC = CameraCustomPickerController()
        pushVC.delegate = self
        pushVC.sourceType = .camera
        pushVC.cameraFlashMode = .off
        pushVC.cameraDevice = .front
        pushVC.modalPresentationStyle = .overFullScreen
        present(pushVC, animated: true)
    }
    
    private func checkAlbumPermission() {
        PHPhotoLibrary.requestAuthorization({ status in
            switch status {
            case .authorized:
                print("Album: 권한 허용")
            case .denied:
                print("Album: 권한 거부")
            case .restricted, .notDetermined:
                print("Album: 선택하지 않음")
            default:
                break
            }
        })
    }
    
    @objc func importImage(_ gesture: UITapGestureRecognizer) {
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertStyle = UIAlertController.Style.alert
        }
        let actionSheet = UIAlertController(title: "배경 사진 가져오기", message: nil, preferredStyle: alertStyle)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.cameraImagePicker()
            })
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.libraryImagePicker(withType: .photoLibrary)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: false, completion: nil)
    }
}

extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        return scaledImage
    }
}

extension CardCreateViewController {
    private func rootUIImageViewConstraints() {
        rootUIImageView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.80)
            make.height.equalTo(self.view.bounds.width * 0.75 * 0.75)
            make.top.equalTo(self.view.snp.top).offset(60)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.80)
            make.height.equalTo(self.view.bounds.width * 0.75 * 0.75)
            make.top.equalTo(self.view.snp.top).offset(60)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func canvasViewConstraints() {
        canvasView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.80)
            make.height.equalTo(self.view.bounds.width * 0.75 * 0.75)
            make.top.equalTo(self.view.snp.top).offset(60)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func introWordingLabelConstraints() {
        introWordingLabel.snp.makeConstraints({ make in
            make.width.equalTo(500)
            make.height.equalTo(50)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func imageShadowViewConstraints() {
        imageShadowView.snp.makeConstraints({ make in
            make.width.equalTo(740)
            make.height.equalTo(120)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.snp.bottom).offset(-140)
        })
    }
    
    private func collectionViewConstraints() {
        collectionView.snp.makeConstraints({ make in
            make.width.equalTo(740)
            make.height.equalTo(120)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.snp.bottom).offset(-140)
        })
    }
    
    private func buttonLabelConstraints() {
        buttonLabel.snp.makeConstraints({ make in
            make.width.equalTo(90)
            make.height.equalTo(450)
            make.leading.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func cameraButtonConstraints() {
        cameraButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(20)
        })
    }
    
    private func backgroundOnButtonConstraints() {
        backgroundOnButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(cameraButton.snp.bottom).offset(20)
        })
    }
    
    private func backgroundOffButtonConstraints() {
        backgroundOffButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(cameraButton.snp.bottom).offset(20)
        })
    }
    
    private func dividerConstraints() {
        divider.snp.makeConstraints({ make in
            make.width.equalTo(65)
            make.height.equalTo(1)
            make.centerX.equalTo(cameraButton.snp.centerX)
            make.top.equalTo(buttonLabel.snp.top).offset(150)
        })
    }
    
    private func pencilOnButtonConstraints() {
        pencilOnButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(divider.snp.bottom).offset(20)
        })
    }
    
    private func pencilOffButtonConstraints() {
        pencilOffButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(divider.snp.bottom).offset(20)
        })
    }
    
    private func stickerOnButtonConstraints() {
        stickerOnButton.snp.makeConstraints({ make in
            make.width.equalTo(80.7)
            make.height.equalTo(63.76)
            make.leading.equalTo(buttonLabel.snp.leading).offset(10)
            make.top.equalTo(divider.snp.bottom).offset(90)
            make.bottom.equalTo(buttonLabel.snp.bottom).offset(-20)
        })
    }
    
    private func stickerOffButtonConstraints() {
        stickerOffButton.snp.makeConstraints({ make in
            make.width.equalTo(80.7)
            make.height.equalTo(63.76)
            make.leading.equalTo(buttonLabel.snp.leading).offset(10)
            make.top.equalTo(divider.snp.bottom).offset(90)
            make.bottom.equalTo(buttonLabel.snp.bottom).offset(-20)
        })
    }
}