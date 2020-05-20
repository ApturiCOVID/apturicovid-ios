import Foundation
import RxSwift

class RestClient {
    func request(urlString: String, body: Data? = nil, method: String = "GET") -> Observable<Data> {
        return Observable.create({ (observer) -> Disposable in
            guard
                let url = URL(string: urlString) else {
                    observer.onError(NSError.make("Error creating url"))
                    return Disposables.create()
            }
            
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = method
            request.httpBody = body
            print("Curl: \(request.curlString)")
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, urlResponse, error) in

                data.map {
                    print("Response: \(String(data: $0, encoding: .utf8) ?? "")")
                }

                guard let response = urlResponse as? HTTPURLResponse else {
                    observer.onError(NSError.make("Error parsing response"))
                    return
                }
                
                if response.statusCode != 200 {
                    observer.onError(NSError.make("\(response.statusCode) : \(urlString)"))
                    return
                }
                
                if let responseData = data, error == nil {
                    observer.onNext(responseData)
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
}
