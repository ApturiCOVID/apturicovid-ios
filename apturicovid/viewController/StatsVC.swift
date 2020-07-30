import UIKit
import RxSwift
import RxCocoa

struct LayoutParams {
    var cellHeightAspectRatio: CGFloat {
        switch UIApplication.shared.preferredContentSizeCategory {
        case .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return 0.6
        case .accessibilityMedium, .accessibilityLarge:
            return 0.5
        default:
            return 0.4
        }
    }
    let contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 30, right: 0)
    let sectionInset = UIEdgeInsets(top: 30, left: 0, bottom: 16, right: 0)
}

class StatsVC: BaseViewController {

    @IBOutlet weak var statsCollectionView: UICollectionView!
    @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
    
    let params = LayoutParams()
    private let refreshControl = UIRefreshControl()
    
    var stats: Stats? {
        didSet {
            if oldValue != stats {
                statsCollectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statsCollectionView.dataSource = self
        statsCollectionView.delegate = self
        statsCollectionView.contentInset.top = params.contentInset.top
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        statsCollectionView.refreshControl = refreshControl
        refreshControl.layer.zPosition = -1
        
        NotificationCenter.default.rx
            .notification(UIContentSizeCategory.didChangeNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
                self?.statsCollectionView.collectionViewLayout.invalidateLayout()
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(.reachabilityChanged)
            .subscribe(onNext: { [weak self] notification in
                if (notification.object as? Reachability.Connection)?.available == true {
                    self?.loadData()
                }
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
        .notification(UIApplication.didBecomeActiveNotification)
        .subscribe(onNext: { [weak self] (_) in
            self?.loadData()
        })
        .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
        .notification(UIApplication.willResignActiveNotification)
        .subscribe(onNext: { [weak self] (_) in
            self?.resetRefreshControl()
        })
        .disposed(by: disposeBag)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        showConnectivityWarningIfRequired()
        loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        resetRefreshControl()
    }
    
    func resetRefreshControl(){
        refreshControl.endRefreshing()
        let offset = CGPoint(x: 0, y: view.safeAreaInsets.top)
        print(offset)
        statsCollectionView.resetScrollToInsts(animated: true, aditinalOffset: offset)
    }

    @objc func refreshData(){
        loadData(forceApi: true)
    }
    
    func loadData(forceApi: Bool = false){
        StatsClient.shared.getStats(from: forceApi ? .Api : .Auto)
        .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
        .observeOn(MainScheduler.instance)
            .share()
            .subscribe(onNext: { [weak self] (stats) in
                self?.stats = stats
                },onError: {  [weak self] error in
                    justPrintError(error)
                    self?.refreshControl.endRefreshing()
                }, onCompleted: { [weak self] in
                    self?.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
    }
    
    override func translate() {
        statsCollectionView.reloadData()
    }
}

//MARK: - Datasource
extension StatsVC : UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stats?.valueFields.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: section)) as? StatsHeaderView {
            
            return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingCompressedSize.height),
                                                      withHorizontalFittingPriority: .required,
                                                      verticalFittingPriority: .fittingSizeLevel)
        } else {
            return CGSize(width: 1, height: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let footerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter, at: IndexPath(row: 0, section: section)) as? StatsFooterView {
            
            footerView.translatesAutoresizingMaskIntoConstraints = false
            return footerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingCompressedSize.height),
                                                      withHorizontalFittingPriority: .required,
                                                      verticalFittingPriority: .fittingSizeLevel)
        } else {
            return CGSize(width: 1, height: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: StatsHeaderView.identifier,
                                                                             for: indexPath) as! StatsHeaderView
            
            if let stats = stats {
                headerView.setupData(with: stats.headerField)
            } else {
                headerView.setupData(with: Stats.defaultHeaderField)
            }
            
            return headerView
            
        case UICollectionView.elementKindSectionFooter:
                
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: StatsFooterView.identifier,
                                                                             for: indexPath) as! StatsFooterView
            footerView.setup(with: "detailed_stats".translated, linkUrl: URL(string: "https://arkartassituacija.gov.lv/")!)
            return footerView
        default:
            return UICollectionReusableView(frame: .zero)
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.section + indexPath.row
        
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: StatsCollectionViewCell.identifier,
                                                       for: indexPath) as! StatsCollectionViewCell
            
        cell.setupData(with: stats!.valueFields[index])
            
        return cell
    }
}

//MARK: - Flow layout
extension StatsVC: UICollectionViewDelegateFlowLayout {
    
    func availableWidth(in collectionView: UICollectionView) -> CGFloat {
        collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellWidth = availableWidth(in: collectionView)
        let cellHeight = cellWidth * params.cellHeightAspectRatio
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return stats == nil ? .zero : params.sectionInset
    }
}

//MARK: - UIScrollViewDelegate
extension StatsVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        statusBarBlurView.effect = offset > -view.safeAreaInsets.top ? UIBlurEffect(style: .light) : nil
    }
    
}

fileprivate extension Stats {
        
    static let defaultHeaderField = HeaderValueField(title: "latvia_covid_statistics".translated,
                                                     description: "data_renewed".translated + "-")
    
    var headerField: HeaderValueField {
        HeaderValueField(title: "latvia_covid_statistics".translated,
                         description: "data_renewed".translated + dateString)
    }

    var valueFields: [DoubleValueField<Int>] {
        [
            DoubleValueField(title: "new_cases".translated.capitalized,
                             field1: ValueField(valueTitle: "total".translated.capitalized,
                                                value: totalInfectedCount),
                             field2: ValueField(valueTitle: "yesterday".translated.capitalized,
                                                value: yesterdaysInfectedCount)),
            
            DoubleValueField(title: "deaths".translated.capitalized,
                             field1: ValueField(valueTitle: "total".translated.capitalized,
                                                value: totalDeathCount),
                             field2: ValueField(valueTitle: "yesterday".translated.capitalized,
                                                value: yesterdayDeathCount)),
            
            DoubleValueField(title: "tested".translated.capitalized,
                             field1: ValueField(valueTitle: "total".translated.capitalized,
                                                value: totalTestsCount),
                             field2: ValueField(valueTitle: "yesterday".translated.capitalized,
                                                value: yesterdaysTestsCount)),
            
            DoubleValueField(title: "recovered".translated.capitalized,
                             field1: ValueField(valueTitle: "total".translated.capitalized,
                                                value: totalRecoveredCount),
                             field2: ValueField(valueTitle: "", value: nil))
        ]
    }
}
