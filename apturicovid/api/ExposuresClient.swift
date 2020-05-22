import Foundation
import RxSwift
import ExposureNotification
import CocoaLumberjack

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
    
    func uploadExposures() -> Observable<Bool> {
        guard
            let phone = LocalStore.shared.phoneNumber,
            let exposureToken = phone.token else {
                DDLogInfo("User is anonymous - skipping exposure upload")
                return Observable.just(true)
        }
        
        var pendingExposures = LocalStore.shared.exposures.filter { $0.uploadetAt == nil }
        
        guard pendingExposures.count > 0 else {
            DDLogInfo("No new exposures to upload - skipping")
            return Observable.just(true)
        }
        
        guard let bodyData = try? JSONEncoder().encode(ExposureUploadRequest(exposure_token: exposureToken, exposures: pendingExposures.map { $0.exposure })) else {
            return Observable.error(NSError.make("Enable to encode exposures"))
        }
        
        return
            request(urlString: "\(baseUrl)/exposure_summaries", body: bodyData, method: "POST")
                .do(onNext: { (_) in
                    for i in 0...pendingExposures.count - 1 {
                        pendingExposures[i].markUploaded()
                    }
                    
                    let uuids = pendingExposures.map { $0.uuid }
                    let previousExposures = LocalStore.shared.exposures.filter { !uuids.contains($0.uuid) }
                    LocalStore.shared.exposures = previousExposures + pendingExposures
                })
                .map { _ in return true }
    }
    
    func getDiagnosisBatchUrls() -> Observable<[(url: URL, index: String)]> {
        return request(urlString: "\(exposureFilesBaseUrl)/index.txt")
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
        return getDiagnosisBatchUrls()
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
                    .do(onNext: { (_) in
                        LocalStore.shared.lastDownloadedBatchIndex = Int(nextUrls.last?.index ?? "0")!
                    })
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
    
    func getExposuresConfiguration() -> Observable<ENExposureConfiguration?> {
        return request(urlString: "\(filesBaseUrl)/exposure_configurations/v1/ios.json")
            .map { (data) -> ENExposureConfiguration? in
                guard let exposureConfiguration = try? JSONDecoder().decode(ExposureConfiguration.self, from: data) else {
                    return nil
                }
                
                return ENExposureConfiguration(from: exposureConfiguration)
        }
    }
}
