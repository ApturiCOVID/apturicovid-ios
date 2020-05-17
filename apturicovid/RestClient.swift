import Foundation
import RxSwift
import ExposureNotification

class RestClient {
    static let shared = RestClient()
    
    let baseUrl = "https://apturicovid-staging.spkc.gov.lv/api/v1"
    let exposureKeyS3url = "https://s3.lvdc.gov.lv/apturicovid-staging-dkfs/v0"
    
    private func getRemoteExposureKeyBatchUrl(index: Int) -> URL? {
        return URL(string: "\(exposureKeyS3url)\(index).bin")
    }
    
    func post(urlString: String, body: Data) -> Observable<Data> {
        return Observable.create({ (observer) -> Disposable in
            guard
                let url = URL(string: "\(self.baseUrl)\(urlString)") else {
                    observer.onError(NSError.make("Error creating url"))
                    return Disposables.create()
            }
            
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = body
            print("Curl: \(request.curlString)")
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, urlResponse, error) in
                data.map {
                    print("Response: \(String(data: $0, encoding: .utf8) ?? "")")
                }
                if let data = data, error == nil {
                    observer.onNext(data)
                } else {
                    observer.onError(error ?? NSError.make("No Data Received"))
                }
            })
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        })
    }
    
    func downloadExposureKeyBatch(url: URL, index: Int) -> Observable<URL?> {
        return Observable.create { (observer) -> Disposable in
            let request = URLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                if let data = data, error == nil {
                    do {
                        let uuid = UUID().uuidString
                        let localUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("diagnosisKeys-\(uuid)")
                        try data.write(to: localUrl)
                        
                        LocalStore.shared.lastDownloadedBatchIndex = index
                        observer.onNext(localUrl)
                    } catch {
                        observer.onNext(nil)
                    }
                } else {
                    observer.onNext(nil)
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    func getDiagnosisKeyFileUrls(startingAt index: Int, completion: @escaping (Result<[(URL, Int)], Error>) -> Void) {
        guard let url = URL(string: "\(self.exposureKeyS3url)/index.txt") else {
            completion(.failure(NSError.make("Error creating url")))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let data = data,
                let urlsString = String(data: data, encoding: .utf8),
                error == nil {
                
                let urls = urlsString
                    .components(separatedBy: "\n")
                    .compactMap { URL(string: $0) }
                    .map { (url) -> (URL, Int) in
                        let pathIndex = url.pathComponents.last?.components(separatedBy: ".").first ?? "0"
                        return (url, Int(pathIndex) ?? 0)
                    }
                
                let nextUrls = urls.filter { (url, i) -> Bool in
                    return i > index
                }
                
                completion(.success(nextUrls))
                
            } else {
                completion(.failure(NSError.make("Error request batch urls")))
            }
        }
        
        task.resume()
    }
    
    func downloadDiagnosisKeyFile(at remoteURL: URL, index: Int, completion: @escaping (Result<URL, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: remoteURL) { (data, _, error) in
            if let data = data, error == nil {
                do {
                    let uuid = UUID().uuidString
                    let localUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("diagnosisKeys-\(uuid)")
                    try data.write(to: localUrl)
                    
                    LocalStore.shared.lastDownloadedBatchIndex = index
                    completion(.success(localUrl))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError.make("Error downloading batch")))
            }
        }
        task.resume()
    }
    
    func getExposureKeyBatchUrls() -> Observable<[(url: URL, index: String)]> {
        return Observable.create { (observer) -> Disposable in
            guard let url = URL(string: "\(self.exposureKeyS3url)/index.txt") else {
                observer.onError(NSError.make("Error creating url"))
                return Disposables.create()
            }
            
            let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
                if let data = data,
                    let urlsString = String(data: data, encoding: .utf8),
                    error == nil {
                    let urls = urlsString
                        .components(separatedBy: "\n")
                        .compactMap { URL(string: $0) }
                        .map { (url) -> (url: URL, index: String) in
                            let index = url.pathComponents.last?.components(separatedBy: ".").first ?? "0"
                            return (url, index)
                    }
                    observer.onNext(urls)
                    observer.onCompleted()
                } else {
                    observer.onError(NSError.make("Error request batch urls"))
                }
            }
            
            task.resume()
            
            return Disposables.create()
        }
    }
    
    func downloadDiagnosisBatches(startAt index: Int) -> Observable<[URL?]> {
        return getExposureKeyBatchUrls()
            .flatMap { (urls) -> Observable<[URL?]> in
                let lastIndex = LocalStore.shared.lastDownloadedBatchIndex
                
                let nextUrls = urls.filter { (url, index) -> Bool in
                    return Int(index) ?? 0 > lastIndex
                }
                
                if nextUrls.isEmpty { return Observable.just([]) }
                
                return Observable.zip(nextUrls.map({ (url, index) -> Observable<URL?> in
                    return self.downloadExposureKeyBatch(url: url, index: Int(index) ?? 0)
                }))
        }
    }
    
    func uploadDiagnosis(token: String, keys: [ENTemporaryExposureKey]) -> Observable<Data> {
        let uploadBody = DiagnosisUploadRequest(token: token, diagnosisKeys: keys.map{ DiagnosisKey(from: $0) })
        
        let encoder = JSONEncoder.init()
        guard let data = try? encoder.encode(uploadBody) else { return Observable.error(NSError.make("Unable to make upload request body")) }
        
        return post(urlString: "/diagnosis_keys", body: data)
    }
    
    func requestPhoneVerification(phoneNumber: String) -> Observable<PhoneVerificationRequestResponse?> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(PhoneVerificationRequest(phone_number: phoneNumber))
        
        guard body?.isEmpty == false else {
            return Observable.error(NSError.make("Error creating request"))
        }
        
        return post(urlString: "/phone_verifications", body: body!)
            .map { (data) -> PhoneVerificationRequestResponse? in
                return try? JSONDecoder().decode(PhoneVerificationRequestResponse.self, from: data)
        }
    }
    
    func requestPhoneConfirmation(token: String, code: String) -> Observable<PhoneConfirmationResponse?> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(PhoneConfirmationRequest(token: token, code: code))
        
        guard body?.isEmpty == false else {
            return Observable.error(NSError.make("Error creating request"))
        }
        
        return post(urlString: "/phone_verifications/verify", body: body!)
            .map { (data) -> PhoneConfirmationResponse? in
                return try? JSONDecoder().decode(PhoneConfirmationResponse.self, from: data)
        }
    }
    
    func requestDiagnosisUploadKey(code: String) -> Observable<UploadKeyResponse?> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(UploadKeyVerificationRequest(code: code))
        
        guard body?.isEmpty == false else {
            return Observable.error(NSError.make("Error creating request"))
        }
        
        return post(urlString: "/upload_keys/verify", body: body!)
            .map { (data) -> UploadKeyResponse? in
                return try? JSONDecoder().decode(UploadKeyResponse.self, from: data)
        }
    }
}
