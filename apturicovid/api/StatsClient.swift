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
            statsObservable = getStatsFromLocalStorage().concat(getStatsFromApi(forced: false))
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
        
        guard !forced && !shouldFetchFromApi() else {
            return Observable.empty()
        }

        return self.request(urlString: "\(filesBaseUrl)/stats/v1/covid-stats.json", body: nil, method: "GET")
        .compactMap { try? Stats.decoder.decode(Stats.self, from: $0) }
        .do(onNext: { stats in
            LocalStore.shared.stats = stats
            LocalStore.shared.lastStatsFetchTime = Date()
        })
        
    }
    
    private func getStatsFromLocalStorage() -> Observable<Stats> {
        LocalStore.shared.stats.map(Observable.just) ?? Observable.empty()
    }
    
}
