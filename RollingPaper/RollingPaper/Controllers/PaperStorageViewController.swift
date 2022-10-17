//
//  PaperStorageViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/12.
//

import UIKit
import SnapKit
import Combine

class PaperStorageViewController: UIViewController {
    private let viewModel = PaperStorageViewModel()
    private let input: PassthroughSubject<PaperStorageViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var paperCollectionView: CollectionView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setMainView()
        setCollectionView()
    }
    
    // view가 나타나면 알려주기
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidAppear)
    }
    
    // view가 사라지면 알려주기
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        input.send(.viewDidDisappear)
    }
    
    // Input이 설정될때마다 자동으로 transform 함수가 실행되고 그 결과값으로 Output이 오면 어떤 행동을 할지 정하기
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                // 페이퍼에 변화가 있으면 UI 업데이트 하기
                case .initPapers, .papersAreUpdatedInDatabase, .papersAreUpdatedByTimer:
                    self.paperCollectionView?.reloadData()
                }
            })
            .store(in: &cancellables)
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .white
    }
    
    // 컬렉션 뷰 초기화
    private func setCollectionView() {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets(top: 28, left: 28, bottom: 48, right: 28)
        collectionViewLayer.minimumInteritemSpacing = 20
        collectionViewLayer.minimumLineSpacing = 28
        collectionViewLayer.headerReferenceSize = .init(width: 116, height: 29)
        
        paperCollectionView = CollectionView(frame: .zero, collectionViewLayout: collectionViewLayer)
        guard let collectionView = paperCollectionView else {return}
        
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.register(CollectionCell.self, forCellWithReuseIdentifier: CollectionCell.identifier)
        collectionView.register(CollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionHeader.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints({ make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(0)
        })
    }
}

// 컬렉션 뷰에 대한 여러 설정들을 해줌
extension PaperStorageViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 셀의 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 200, height: 200)
    }
    // 섹션별 셀 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return viewModel.openedPapers.count
        } else {
            return viewModel.closedPapers.count
        }
    }
    // 섹션의 개수
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    // 특정 위치의 셀
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionCell.identifier, for: indexPath) as? CollectionCell else {return UICollectionViewCell()}
        
        if indexPath.section == 0 {
            cell.setCell(paper: viewModel.openedPapers[indexPath.item], now: viewModel.currentTime)
        } else {
            cell.setCell(paper: viewModel.closedPapers[indexPath.item], now: viewModel.currentTime)
        }
        return cell
    }
    // 특정 위치의 헤더
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let supplementaryView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CollectionHeader.identifier,
                for: indexPath
            ) as? CollectionHeader else {return UICollectionReusableView()}
            
            if indexPath.section == 0 {
                supplementaryView.setHeader(text: "진행중인 페이퍼")
            } else {
                supplementaryView.setHeader(text: "종료된 페이퍼")
            }
            return supplementaryView
        } else {
            return UICollectionReusableView()
        }
    }
    // 특정 셀 눌렀을 떄의 동작
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        // TODO: 터치한 페이퍼 뷰로 이동
        if indexPath.section == 0 {
            print("진행중인 페이퍼 \(indexPath.item+1) 터치됨")
        } else {
            print("종료된 페이퍼 \(indexPath.item+1) 터치됨")
        }
        return true
    }
}

// 진행중인 페이퍼와 종료된 페이퍼들을 모두 보여주는 컬렉션 뷰
private class CollectionView: UICollectionView {}

// 컬렉션 뷰에서 섹션의 제목을 보여주는 뷰
private class CollectionHeader: UICollectionReusableView {
    static let identifier = "CollectionHeader"
    private let title = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        addSubview(title)
        
        title.font = .preferredFont(forTextStyle: .title2)
        title.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(34)
        })
    }
    
    func setHeader(text: String) {
        title.text = text
    }
}

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰
private class CollectionCell: UICollectionViewCell {
    static let identifier = "CollectionCell"
    private let cell = UIView()
    private let preview = UIImageView()
    private let timer = UIStackView()
    private let clock = UIImageView()
    private let time = UILabel()
    private let title = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        addSubview(cell)
        cell.addSubview(preview)
        cell.addSubview(title)
        cell.addSubview(timer)
        timer.addArrangedSubview(clock)
        timer.addArrangedSubview(time)
        
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        preview.layer.masksToBounds = true
        preview.layer.cornerRadius = 12
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(196)
            make.height.equalTo(134)
        })
        
        title.font = .preferredFont(forTextStyle: .body)
        title.textColor = UIColor(rgb: 0x808080)
        title.textAlignment = .center
        title.snp.makeConstraints({ make in
            make.top.equalTo(preview.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        })
        
        timer.distribution = .equalSpacing
        timer.layoutMargins = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        timer.isLayoutMarginsRelativeArrangement = true
        timer.layer.cornerRadius = 12
        timer.spacing = 5
        timer.snp.makeConstraints({ make in
            make.top.equalTo(title.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        })
        
        clock.image = UIImage(systemName: "timer")
        clock.tintColor = .white
        clock.contentMode = .scaleAspectFit
        clock.snp.makeConstraints({ make in
            make.width.equalTo(15)
            make.height.equalTo(15)
        })
        
        time.font = .preferredFont(forTextStyle: .body)
        time.textAlignment = .right
        time.textColor = .white
    }
    
    // 초를 05:17(시간:분) 형식으로 바꾸기
    private func changeTimeFormat(second: Int) -> String {
        let hour = Int(second/3600)
        let minute = Int((second - (hour*3600))/60)
        var hourString = String(hour)
        var minuteString = String(minute)
        if hourString.count == 1 {
            hourString = "0" + hourString
        }
        if minuteString.count == 1 {
            minuteString = "0" + minuteString
        }
        
        return hourString + ":" + minuteString
    }
    
    // 날짜를 2022.10.13 같은 형식으로 바꾸기
    private func changeDateFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y.M.d"
        return dateFormatter.string(from: date)
    }
    
    func setCell(paper: PaperPreviewModel, now: Date) {
        let timeInterval = Int(paper.endTime.timeIntervalSince(now))
        if timeInterval > 0 {
            // 진행중인 페이퍼라면
            timer.backgroundColor = UIColor(rgb: 0xFF3B30)
            time.text = changeTimeFormat(second: timeInterval)
            clock.isHidden = false
        } else {
            // 종료된 페이퍼라면
            timer.backgroundColor = UIColor(rgb: 0xADADAD)
            time.text = changeDateFormat(date: now)
            clock.isHidden = true
        }
        
        title.text = paper.title
        // TODO: 프리뷰 구현해서 이미지에 넣어주기 (FirebaseStorageManager)
        // preview.image = (paper.thumbnailURLString 으로 썸네일 다운) ?? paper.template.thumbnail
        preview.image = paper.template.thumbnail
    }
}