import Foundation
import RxSwift
import ExposureNotification

class ExposuresClient: RestClient {
    static let shared = ExposuresClient()
    
    private func getRemoteExposureKeyBatchUrl(index: Int) -> URL? {
        return URL(string: "\(filesBaseUrl)\(index).bin")
    }
    
    func downloadFile(url: URL) -> Observable<URL> {
        return request(urlString: url.absoluteString)
            .map { (data) -> URL in
                let fileManager = FileManager.default
                let fileUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    .appendingPathComponent(url.pathComponents.last!)
                
                try? data.write(to: fileUrl)
                
                return fileUrl
            }
    }
    
    func downloadExposureKeyBatch(url: URL, index: Int) -> Observable<URL?> {
        return Observable.create { (observer) -> Disposable in
            let request = URLRequest(url: url)

            let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                if let data = data, error == nil {
                    do {
                        let localUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("day-\(index).zip")
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
        guard let url = URL(string: "\(exposureFilesBaseUrl)/index.txt") else {
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
    
    func uploadExposures(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard
            let phone = LocalStore.shared.phoneNumber,
            let exposureToken = phone.token else {
            completion(.failure(NSError.make("Cannot upload exposures without phone number")))
            return
        }
        
        var pendingExposures = LocalStore.shared.exposures.filter { $0.uploadetAt == nil }
        
        guard let bodyData = try? JSONEncoder().encode(ExposureUploadRequest(exposure_token: exposureToken, exposures: pendingExposures.map { $0.exposure })) else {
            completion(.failure(NSError.make("Enable to encode exposures")))
            return
        }
        
        guard let url = URL(string: "\(baseUrl)/exposure_summaries") else {
            completion(.failure(NSError.make("Unable to make exposure upload url")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpBody = bodyData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                if let error = error {
                    completion(.failure(error))
                }
                completion(.failure(NSError.make("Upload task failed")))
                return
            }
            
            guard pendingExposures.count > 0 else {
                completion(.success(true))
                return
            }
            
            for i in 0...pendingExposures.count - 1 {
                pendingExposures[i].markUploaded()
            }
            
            print(pendingExposures)
            
            completion(.success(true))
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
//        return request(urlString: "\(exposureFilesBaseUrl)/index.txt")
        return request(urlString: "https://s3.us-east-1.amazonaws.com/apturicovid-development/dkfs/v1/index.txt")
            .map { (data) -> [(url: URL, index: String)] in
                guard let urlsString = String(data: data, encoding: .utf8) else {
                    return []
                }
                
                return urlsString
                    .components(separatedBy: "\n")
                    .compactMap { URL(string: $0) }
                    .map { (url) -> (url: URL, index: String) in
                        let index = url.pathComponents.last?.components(separatedBy: ".").first ?? "0"
                        return (url, index)
                    }
            }
    }
    
    func downloadDiagnosisBatches(startAt index: Int) -> Observable<[URL]> {
        return getExposureKeyBatchUrls()
            .flatMap { (urls) -> Observable<[URL]> in
                let lastIndex = index
                
                let nextUrls = urls.filter { (url, index) -> Bool in
                    return Int(index) ?? 0 > lastIndex
                }
                
                if nextUrls.isEmpty { return Observable.just([]) }
                
                let urlsToDownload = nextUrls.map { (url, index) -> [URL] in
                    let binUrl = url.deletingLastPathComponent().appendingPathComponent("\(index).bin")
                    let sigUrl = url.deletingLastPathComponent().appendingPathComponent("\(index).sig")
                    return [binUrl, sigUrl]
                }
                .flatMap { $0 }
                
                return Observable.zip(urlsToDownload.map({ url -> Observable<URL> in
                    return self.downloadFile(url: url)
                }))
        }
    }
    
    func uploadDiagnosis(token: String, keys: [ENTemporaryExposureKey]) -> Observable<Data> {
        let uploadBody = DiagnosisUploadRequest(token: token, diagnosisKeys: keys.map{ DiagnosisKey(from: $0) })
        
        let encoder = JSONEncoder.init()
        guard let data = try? encoder.encode(uploadBody) else { return Observable.error(NSError.make("Unable to make upload request body")) }
        
        return request(urlString: "\(baseUrl)/diagnosis_keys", body: data, method: "POST")
    }
    
    func requestDiagnosisUploadKey(code: String) -> Observable<UploadKeyResponse?> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(UploadKeyVerificationRequest(code: code))
        
        guard body?.isEmpty == false else {
            return Observable.error(NSError.make("Error creating request"))
        }
        
        return request(urlString: "\(baseUrl)/upload_keys/verify", body: body!, method: "POST")
            .map { (data) -> UploadKeyResponse? in
                return try? JSONDecoder().decode(UploadKeyResponse.self, from: data)
        }
    }
}
