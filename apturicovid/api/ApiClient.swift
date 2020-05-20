import Foundation
import RxSwift
import DeviceCheck

class ApiClient: RestClient {
    static let shared = ApiClient()
    
    private func obtainDeviceToken() -> Observable<String> {
        return Observable.create { (observer) -> Disposable in
            let currentDevice = DCDevice.current
            guard currentDevice.isSupported else {
                observer.onError(NSError.make("DC: Device unsupported"))
                return Disposables.create()
            }
            
            currentDevice.generateToken { (data, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    data.map {
                        observer.onNext($0.base64EncodedString())
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    private func makePhoneVerificationCall(phoneNumber: String, deviceToken: String) -> Observable<PhoneVerificationRequestResponse?> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(PhoneVerificationRequest(phone_number: phoneNumber, device_check_token: deviceToken))
        
        guard body?.isEmpty == false else {
            return Observable.error(NSError.make("Error creating request"))
        }
        
        return request(urlString: "\(baseUrl)/phone_verifications", body: body!, method: "POST")
            .map { (data) -> PhoneVerificationRequestResponse? in
                return try? JSONDecoder().decode(PhoneVerificationRequestResponse.self, from: data)
        }
    }
    
    func requestPhoneVerification(phoneNumber: String) -> Observable<PhoneVerificationRequestResponse?> {
        return obtainDeviceToken()
            .flatMap { (deviceToken) -> Observable<PhoneVerificationRequestResponse?> in
                return self.makePhoneVerificationCall(phoneNumber: phoneNumber, deviceToken: deviceToken)
        }
    }
    
    func requestPhoneConfirmation(token: String, code: String) -> Observable<PhoneConfirmationResponse?> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(PhoneConfirmationRequest(token: token, code: code))
        
        guard body?.isEmpty == false else {
            return Observable.error(NSError.make("Error creating request"))
        }
        
        return request(urlString: "\(baseUrl)/phone_verifications/verify", body: body!, method: "POST")
            .map { (data) -> PhoneConfirmationResponse? in
                return try? JSONDecoder().decode(PhoneConfirmationResponse.self, from: data)
        }
    }
    
    
    func fetchStats(ignoreOutdated: Bool = true) -> Observable<Stats> {
        
        return Observable<Stats>.create { observer -> Disposable in
            
            // Return stored data if it updated in last 24 hour
            if let stats = LocalStore.shared.stats {
                
                if ignoreOutdated && stats.updatedAt.distance(to: Date()) < 24 * 60 {
                    observer.onNext(stats)
                } else {
                    observer.onNext(stats)
                }
            }
            
            // Fetch new data
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
