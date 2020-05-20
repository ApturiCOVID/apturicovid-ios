//
//  StatsClient.swift
//  apturicovid
//
//  Created by Artjoms Spole on 20/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import Foundation
import RxSwift

class StatsClient: RestClient {
    
    private static let fetchThrottle: TimeInterval = 5 * 60 // 5 min
    private static let statTtlInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    static let shared = StatsClient()
    private override init() { }
    
    func getStats(forceFromApi: Bool = false, ignoreOutdated: Bool = false) -> Observable<Stats> {
        
        return Observable<Stats>.create { [weak self] observer -> Disposable in
            
            let disposable = Disposables.create()
            guard let `self` = self else { return disposable }
            
            // Return stored data
            if !forceFromApi {
                if let stats = LocalStore.shared.stats {
                    
                    // Skip outdated if required data
                    if ignoreOutdated && stats.updatedAt.distance(to: Date()) < StatsClient.statTtlInterval {
                        observer.onNext(stats)
                    } else {
                        observer.onNext(stats)
                    }
                }
            }
            
            // Complete if recently got new stats
            guard LocalStore.shared.lastStatsFetchTime.distance(to: Date()) < StatsClient.fetchThrottle else {
                observer.onCompleted()
                return disposable
            }
            
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
    }
}
