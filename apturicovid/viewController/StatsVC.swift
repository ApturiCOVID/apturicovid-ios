import UIKit
import RxSwift
import RxCocoa

struct LayoutParams {
    let expectedCellCountInRow: Int = UIDevice.current.type == .iPhoneSE ? 1 : 2
    let cellHeightAspectRatio: CGFloat = UIDevice.current.type == .iPhoneSE ? 0.5 : 0.7
    let contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 30, right: 0)
    let sectionInset = UIEdgeInsets(top: 30, left: 0, bottom: 16, right: 0)
    var cellWidthToTotalWidthAspectRatio: CGFloat {
        expectedCellCountInRow == 1 ? 0.9 : 1 / CGFloat(expectedCellCountInRow)
    }
}

class StatsVC: BaseViewController {

    @IBOutlet weak var superView: UIView!
    @IBOutlet weak var welcomeHeaderView: WelcomeHeaderView!
    @IBOutlet weak var statsCollectionView: UICollectionView!
    @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
    
    let params = LayoutParams()
    private let refreshControl = UIRefreshControl()
    
    var stats: Stats? {
        didSet {
            statsCollectionView.reloadData()
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // On SE screen cell background melds with superview color
        // Set superview color from welcomeHeaderView fillcolor
        if UIDevice.current.type == .iPhoneSE {
            superView.backgroundColor = welcomeHeaderView.fillColor
            welcomeHeaderView.isHidden = true
        }

        statsCollectionView.dataSource = self
        statsCollectionView.delegate = self
        statsCollectionView.contentInset.top = params.contentInset.top
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        statsCollectionView.refreshControl = refreshControl
        refreshControl.layer.zPosition = -1
        
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

    }
    
    override func viewDidAppear(_ animated: Bool) {
        showConnectivityWarningIfRequired()
        loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        refreshControl.endRefreshing()
        statsCollectionView.setContentOffset(.zero, animated: false)
    }

    @objc func refreshData(){
        loadData(forceApi: true)
    }
    
    func loadData(forceApi: Bool = false){
        StatsClient.shared.getStats(forceFromApi: forceApi)
        .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
        .observeOn(MainScheduler.instance)
            .share()
            .subscribe(onNext: { [weak self] (stats) in
                if self?.stats != stats { self?.stats = stats }
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
        stats?.totalItemCount ?? 0
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
        let index = indexPath.section * params.expectedCellCountInRow + indexPath.row
        
        if index < stats!.doubleValueFields.count {
            let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: StatsDoubleValueCollectionViewCell.identifier,
                                                           for: indexPath) as! StatsDoubleValueCollectionViewCell
            
            cell.setupData(with: stats!.doubleValueFields[index])
            return cell
        } else {
            let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: StatsSingleValueCollectionViewCell.identifier,
                                                           for: indexPath) as! StatsSingleValueCollectionViewCell
            cell.setupData(with: stats!.singleValueFields[index - stats!.doubleValueFields.count])
            return cell
        }
    }
}

//MARK: - Flow layout
extension StatsVC: UICollectionViewDelegateFlowLayout {
    
    func availableWidth(in collectionView: UICollectionView) -> CGFloat {
        collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellWidth = params.cellWidthToTotalWidthAspectRatio * availableWidth(in: collectionView)
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
        statusBarBlurView.effect = offset > 0 ? UIBlurEffect(style: .light) : nil
    }
    
}

fileprivate extension Stats {
    
    var totalItemCount: Int { singleValueFields.count + doubleValueFields.count }
    
    static let defaultHeaderField = HeaderValueField(title: "latvia_covid_statistics".translated,
                                                     description: "data_renewed".translated + "-")
    
    var headerField: HeaderValueField {
        HeaderValueField(title: "latvia_covid_statistics".translated,
                         description: "data_renewed".translated + dateString)
    }
    
    var singleValueFields: [SingleValueField<Double>] {
        [
            SingleValueField(title: "proportion".translated.capitalized,
                             field: ValueField(valueTitle: "proportion_description".translated.capitalized,
                                               value: infectedTestsProportion))
        ]
    }

    var doubleValueFields: [DoubleValueField<Int>] {
        [
            DoubleValueField(title: "tested".translated.capitalized,
                             field1: ValueField(valueTitle: "together".translated.capitalized,
                                                value: totalTestsCount),
                             field2: ValueField(valueTitle: "yesterday".translated.capitalized,
                                                value: yesterdaysTestsCount)),
            
            DoubleValueField(title: "new_cases".translated.capitalized,
                             field1: ValueField(valueTitle: "together".translated.capitalized,
                                                value: totalInfectedCount),
                             field2: ValueField(valueTitle: "yesterday".translated.capitalized,
                                                value: yesterdaysInfectedCount)),
            
            DoubleValueField(title: "deceased".translated.uppercased(),
                             field1: ValueField(valueTitle: "together".translated.capitalized,
                                                value: totalDeathCount),
                             field2: ValueField(valueTitle: "yesterday".translated.capitalized,
                                                value: yesterdayDeathCount))
        ]
    }
}
