import Foundation
import RxSwift

class StatsClient: RestClient {
    
    /// Specifies how long stats data is valid from .updatedAt
    static let statTtlInterval: TimeInterval = 2 * 24 * 60 * 60 // 2 days
    
    private static let fetchThrottleWifi: TimeInterval = 5 * 60 // 5 min
    private static let fetchThrottleCellular: TimeInterval = 10 * 60 // 10 min
    
    static let shared = StatsClient()
    private override init() { }
    
    enum FetchSource {
        case Api, Auto, Local
    }
    
    func getStats(from source: FetchSource = .Auto, ignoreOutdated: Bool = false) -> Observable<Stats> {
        
        let statsObservable: Observable<Stats>
        
        switch source {
        case .Api:
            statsObservable = getStatsFromApi(forced: true)
        case .Auto:
            statsObservable = Observable.concat([getStatsFromLocalStorage(),getStatsFromApi(forced: false)])
        case .Local:
            statsObservable = getStatsFromLocalStorage()
        }
        
        return statsObservable.filter{ stats in
            ignoreOutdated ? !stats.isOutdated : true
        }
    }
    
    private func shouldFetchFromApi() -> Bool {
        
        guard let stats = LocalStore.shared.stats else {
            return true
        }
        
        var fetchThrottle: TimeInterval {
            switch Reachability.shared?.connection {
            case .cellular: return StatsClient.fetchThrottleCellular
            default:        return StatsClient.fetchThrottleWifi
            }
        }
        
        return stats.isOutdated || LocalStore.shared.lastStatsFetchTime.distance(to: Date()) > fetchThrottle
    }
    
    private func getStatsFromApi(forced: Bool) -> Observable<Stats> {
        
        if forced || shouldFetchFromApi() {
            return Observable<Stats>.create { observer -> Disposable in
                // Fetch data from api
                let apiFetch = self.request(urlString: "\(filesBaseUrl)/stats/v1/covid-stats.json", body: nil, method: "GET")
                    .compactMap{ (data) -> Stats? in
                        do {
                            return try Stats.decoder.decode(Stats.self, from: data)
                        } catch {
                            observer.onError(error)
                            return nil
                        }
                    }.subscribe(onNext: { stats in
                        LocalStore.shared.stats = stats
                        LocalStore.shared.lastStatsFetchTime = Date()
                        observer.onNext(stats)
                    }, onError: {
                        observer.onError($0)
                    }, onCompleted: {
                        observer.onCompleted()
                    })

                return Disposables.create {
                    apiFetch.dispose()
                }
            }
        } else {
            return Observable.empty()
        }
    }
    
    private func getStatsFromLocalStorage() -> Observable<Stats> {
        
        Observable<Stats>.create { observer -> Disposable in
            if let stats = LocalStore.shared.stats {
                observer.onNext(stats)
            }
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
}
