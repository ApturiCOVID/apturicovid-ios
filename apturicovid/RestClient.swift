import Foundation
import RxSwift
import ExposureNotification

class RestClient {
    static let shared = RestClient()
    
    let baseUrl = "https://apturicovid-staging.spkc.gov.lv/api/v1"
    let exposureKeyS3url = "https://apturicovid-backend-minio.makit.lv/dkfs/"
    
    private func getRemoteExposureKeyBatchUrl(index: Int) -> URL? {
        return URL(string: "\(exposureKeyS3url)\(index).bin")
    }
    
    func post(urlString: String, body: Data) -> Observable<Data> {
        return Observable.create({ (observer) -> Disposable in
            guard
                let url = URL(string: "\(self.baseUrl)/\(urlString)") else {
                    observer.onError(NSError.make("Error creating url"))
                    return Disposables.create()
            }
            
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, urlResponse, error) in
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
    
    func downloadExposureKeyBatch(at index: Int) -> Observable<URL?> {
        return Observable.create { (observer) -> Disposable in
            guard let url = self.getRemoteExposureKeyBatchUrl(index: index) else {
                observer.onError(NSError.make("Error creating url"))
                return Disposables.create()
            }
            let request = URLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return observer.onNext(nil)
                }
                
                if httpResponse.statusCode == 404 {
                    return observer.onNext(nil)
                }
                
                if let data = data, error == nil {
                    do {
                        let localUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("diagnosisKeys-\(index)")
                        try data.write(to: localUrl)
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
    
    func downloadIt(index: Int, acc: [URL] = []) -> Observable<[URL]> {
        return self.downloadExposureKeyBatch(at: index)
            .flatMap { (url) -> Observable<[URL]> in
                if let url = url {
                    return self.downloadIt(index: index + 1, acc: acc + [url])
                }
                return Observable.just(acc)
        }
    }
    
    func downloadDiagnosisBatches(startAt index: Int) -> Observable<[URL]> {
        return downloadIt(index: index)
    }
    
    func getDiagnosisKeyFileURLs(startingAt index: Int, completion: @escaping (Result<[URL], Error>) -> Void) {
        _ = downloadDiagnosisBatches(startAt: index)
            .subscribe(onNext: { (urls) in
                completion(.success(urls))
            }, onError: { (err) in
                completion(.failure(err))
            })
    }
    
    func uploadDiagnosis(code: String, keys: [ENTemporaryExposureKey]) -> Observable<Data> {
        let uploadBody = DiagnosisUploadRequest(uploadCode: code, diagnosisKeys: keys.map{ DiagnosisKey(from: $0) })
        
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
    
    func requestDiagnosisUploadKey(code: String) -> Observable<Data> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(UploadKeyVerificationRequest(code: code))
        
        guard body?.isEmpty == false else {
            return Observable.error(NSError.make("Error creating request"))
        }
        
        return post(urlString: "/upload_keys/verify", body: body!)
    }
}
