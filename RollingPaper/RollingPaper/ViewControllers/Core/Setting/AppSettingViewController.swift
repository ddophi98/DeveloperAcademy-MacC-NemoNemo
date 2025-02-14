//
//  AppSettingViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/12.
//

import Combine
import CombineCocoa
import Foundation
import SnapKit
import UIKit

final class AppSettingViewController: UIViewController, UICollectionViewDelegate {
    
    private var viewModel = AppSettingViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<AppSettingViewModel.Section, ListItem>! = nil
    
    private let userPhoto: UIImageView = {
        let photo = UIImageView()
        photo.contentMode = UIView.ContentMode.scaleAspectFill
        return photo
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.text = "Guest"
        name.font = UIFont.preferredFont(forTextStyle: .title1)
        name.sizeToFit()
        return name
    }()
    
    private let userMail: UILabel = {
        let userMail = UILabel()
        userMail.text = "Guest@Email.com"
        userMail.font = UIFont.preferredFont(forTextStyle: .subheadline)
        userMail.sizeToFit()
        return userMail
    }()
    
    private lazy var userNameStack: UIStackView = {
        let userNameStack = UIStackView(arrangedSubviews: [userName, userMail])
        userNameStack.axis = .vertical
        userNameStack.alignment = .leading
        userNameStack.distribution = .equalCentering
        return userNameStack
    }()
    
    private lazy var userNamePhotoStack: UIStackView = {
        let userNamePhotoStack = UIStackView(arrangedSubviews: [userPhoto, userNameStack])
        userNamePhotoStack.axis = .horizontal
        userNamePhotoStack.alignment = .center
        userNamePhotoStack.distribution = .equalSpacing
        userNamePhotoStack.spacing = 16
        return userNamePhotoStack
    }()
    
    private let chevronButton: UIButton = {
        let chevronButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        chevronButton.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        chevronButton.imageView?.contentMode = .scaleAspectFit
        return chevronButton
    }()
    
    private lazy var userInfoStack: UIStackView = {
        let userInfo = UIStackView(arrangedSubviews: [userNamePhotoStack, chevronButton])
        userInfo.axis = .horizontal
        userInfo.alignment = .center
        userInfo.distribution = .equalSpacing
        userInfo.spacing = 0
        userInfo.setCustomSpacing(10, after: userName)
        return userInfo
    }()
    
    lazy var colorSelectAccessory = UICellAccessory.CustomViewConfiguration(
        customView: colorSelectButton,
        placement: .trailing(),
        isHidden: false,
        reservedLayoutWidth: .actual,
        maintainsFixedSize: true
    )
    
    lazy var toggleAccessory = UICellAccessory.CustomViewConfiguration(
        customView: toggleSwitch,
        placement: .trailing(),
        isHidden: false
    )
    
    let colorSelectButton: UISegmentedControl = {
        let colorSelectButton = UISegmentedControl(items: ["Light", "Dark", "System"])
        colorSelectButton.backgroundColor = UIColor.systemGray4
        colorSelectButton.tintColor = .tintColor
        return colorSelectButton
    }()
    
    lazy var toggleSwitch: UISwitch = {
        let toggleSwitch = UISwitch(frame: .zero)
        toggleSwitch.isOn = false
        toggleSwitch.addTarget(self, action: #selector(toggleSwitch(sender: )), for: .valueChanged)
        return toggleSwitch
    }()
    
    lazy var collectionView: UICollectionView = {
        var collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: setupCollectionViewLayout())
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setupGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupViewInitialSetting()
        configureDataSource()
        setupView()
    }
    
    private func bind() {
        viewModel
            .currentUserSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userModel in
                if let userModel = userModel {
                    self?.userName.text = userModel.name
                    self?.userMail.text = userModel.email
                } else {
                    self?.userName.text = "Guest"
                    self?.userMail.text = "Your@Email.signin"
                }
            }
            .store(in: &cancellables)
        viewModel
            .currentPhotoSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                if let image = image {
                    self?.userPhoto.image = image
                } else {
                    self?.userPhoto.image = UIImage(systemName: "person.fill")
                }
            }
            .store(in: &cancellables)
        collectionView.delegate = self
    }
    
    private func setupViewInitialSetting() {
        view.backgroundColor = .systemBackground
        switch UserDefaults.standard.string(forKey: "colorTheme") {
        case "light":
            colorSelectButton.selectedSegmentIndex = 0
        case "dark":
            colorSelectButton.selectedSegmentIndex = 1
        case "system":
            colorSelectButton.selectedSegmentIndex = 2
        default:
            fatalError("unexpected color theme detected!")
        }
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapUserProfile))
        userInfoStack.addGestureRecognizer(tap)
        colorSelectButton.addTarget(self, action: #selector(didChangeValue(segment: )), for: .valueChanged)
    }
    
    private func setupView() {
        view.addSubview(userInfoStack)
        view.addSubview(collectionView)
        userInfoStack.backgroundColor = .systemGray6
        userInfoStack.layer.cornerRadius = 12
        collectionView.delegate = self
        
        userInfoStack.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(150)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        userPhoto.snp.makeConstraints { make in
            make.height.equalTo(userInfoStack.snp.height).inset(10)
            make.width.equalTo(userPhoto.snp.height)
        }
        
        collectionView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(userInfoStack.snp.bottom)
        }
        
        userPhoto.layer.cornerRadius = userPhoto.frame.width / 2
        userPhoto.layer.masksToBounds = true
        userNameStack.layoutMargins = UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension AppSettingViewController { // CollectionView
    
    private func setupCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.headerMode = .none
            config.backgroundColor = .clear
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
        return layout
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AppSettingSectionModel> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            var headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            headerDisclosureOption.tintColor = .label
            switch indexPath {
            case [0, 0]:
                cell.accessories = [.customView(configuration: self.colorSelectAccessory)]
            case [0, 1]:
                cell.accessories = [.customView(configuration: self.toggleAccessory)]
            case [1, 0]:
                let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
                cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
            default:
                break
            }
            content.text = item.title
            let view = UIView()
            view.backgroundColor = .systemGray6
            cell.backgroundView = view
            cell.contentConfiguration = content
        }
        
        let subCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AppSettingSectionSubCellModel> {
            (cell, indexPath, subCellItem) in
            var content = cell.defaultContentConfiguration()
            content.image = subCellItem.icon
            content.text = subCellItem.title
            cell.accessories = indexPath == [1, 1] ? [.label(text: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "_") ] : []
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<AppSettingViewModel.Section, ListItem>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: ListItem) -> UICollectionViewCell? in
            
            switch item {
            case .header(let headerItem):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: headerItem)
            case .subCell(let subCellItem):
                return collectionView.dequeueConfiguredReusableCell(using: subCellRegistration, for: indexPath, item: subCellItem)
            }
        }

        let sections: [AppSettingViewModel.Section] = [.section1, .section2]
        
        var snapshot = NSDiffableDataSourceSnapshot<AppSettingViewModel.Section, ListItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot)
        applySnapshot(sectionData: viewModel.sectionData1, section: .section1)
        applySnapshot(sectionData: viewModel.sectionData2, section: .section2)
    }
    
    private func applySnapshot(sectionData: [AppSettingSectionModel], section: AppSettingViewModel.Section) {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()
        
        for headerItem in sectionData {
            let headerListItem = ListItem.header(headerItem)
            sectionSnapshot.append([headerListItem])
            
            let subCellListItemArray = headerItem.subCells?.map { ListItem.subCell($0) }
            if let subCellListItemArray = subCellListItemArray {
                sectionSnapshot.append(subCellListItemArray, to: headerListItem)
            }
        }
        dataSource.apply(sectionSnapshot, to: section, animatingDifferences: true)
    }
}

extension AppSettingViewController {
    
    @objc private func tapUserProfile() {
        NotificationCenter.default.post(name: .viewChange,
                                        object: nil,
                                        userInfo: [NotificationViewKey.view: "프로필"]
        )
    }

    @objc private func toggleSwitch(sender: UISwitch) {
        if sender.isOn {
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }
    
    @objc private func didChangeValue(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            view.window?.overrideUserInterfaceStyle = .light
            UserDefaults.standard.set("light", forKey: "colorTheme")
        } else if segment.selectedSegmentIndex == 1 {
            view.window?.overrideUserInterfaceStyle = .dark
            UserDefaults.standard.set("dark", forKey: "colorTheme")
        } else {
            view.window?.overrideUserInterfaceStyle = .unspecified
            UserDefaults.standard.set("system", forKey: "colorTheme")
        }
    }
}
