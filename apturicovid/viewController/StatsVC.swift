import UIKit
import RxSwift
import RxCocoa

struct LayoutParams {
    let expectedCellCountInRow: Int = UIDevice.current.type == .iPhoneSE ? 1 : 2
    let cellHeightAspectRatio: CGFloat = 1/3*2
    let contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
    let sectionInset = UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
    var cellWidthToTotalWidthAspectRatio: CGFloat {
        expectedCellCountInRow == 1 ? 0.75 : 1 / CGFloat(expectedCellCountInRow)
    }
}

class StatsVC: BaseViewController {

    @IBOutlet weak var statsCollectionView: UICollectionView!

    let params = LayoutParams()
    
    var stats: Stats? {
        didSet { statsCollectionView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getData()

        statsCollectionView.dataSource = self
        statsCollectionView.delegate = self
        statsCollectionView.contentInset.top = params.contentInset.top

    }

    func getData(){
        StatsClient.shared.getStats()
        .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
        .observeOn(MainScheduler.instance)
        .share()
        .subscribe(onNext: { [weak self] (stats) in
            self?.stats = stats
        }, onError: justPrintError)
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

        if kind == UICollectionView.elementKindSectionHeader {

            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind:  UICollectionView.elementKindSectionHeader,
                                                                             withReuseIdentifier: StatsHeaderView.identifier,
                                                                             for: indexPath) as! StatsHeaderView
            
            if let stats = stats {
                headerView.setupData(with: stats.headerField)
            } else {
                headerView.setupData(with: Stats.defaultHeaderField)
            }
            
            return headerView
        } else {
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
        return params.sectionInset
    }
}

fileprivate extension Stats {
    
    static let defaultHeaderField = HeaderValueField(title: "latvia_covid_statistics".translated,
                                                     description: "data_renewed".translated + " - ")
    
    var headerField: HeaderValueField {
        HeaderValueField(title: "latvia_covid_statistics".translated,
                         description: "data_renewed".translated + dateString)
    }
    
    var totalItemCount: Int { (singleValueFields+doubleValueFields).count }
    
    var singleValueFields: [SingleValueField] {
        [
            SingleValueField(title: "Last",
                             field: ValueField(valueTitle: "all", value: 10))
        ]
    }
    
    var doubleValueFields: [DoubleValueField] {
        [
            DoubleValueField(title: "Last",
                             field1: ValueField(valueTitle: "all", value: 10),
                             field2: ValueField(valueTitle: "all", value: 10)),
            
            DoubleValueField(title: "Last",
                             field1: ValueField(valueTitle: "all", value: 10),
                             field2: ValueField(valueTitle: "all", value: 10)),
            
            DoubleValueField(title: "Last",
                             field1: ValueField(valueTitle: "all", value: 10),
                             field2: ValueField(valueTitle: "all", value: 10))
        ]
    }
}
