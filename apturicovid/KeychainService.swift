import Foundation
import Security

let kSecClassValue                  = NSString(format: kSecClass)
let kSecAttrAccountValue            = NSString(format: kSecAttrAccount)
let kSecValueDataValue              = NSString(format: kSecValueData)
let kSecClassGenericPasswordValue   = NSString(format: kSecClassGenericPassword)
let kSecAttrServiceValue            = NSString(format: kSecAttrService)
let kSecMatchLimitValue             = NSString(format: kSecMatchLimit)
let kSecReturnDataValue             = NSString(format: kSecReturnData)
let kSecMatchLimitOneValue          = NSString(format: kSecMatchLimitOne)

/// Service for storing sensitive user data.
public class KeychainService: NSObject {
    
    private static let service = Bundle.main.bundleIdentifier ?? "Stop Covid"
    
    
    private static let decoder = PropertyListDecoder()
    private static let encoder: PropertyListEncoder = {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return encoder
    }()
    
    
    /// Save  private data for key
    /// - Parameter key: Data key
    /// - Parameter data: Private data
    class func saveData<T>(key: String, data: T) where T: Encodable {
        
        let keychainDuplicateQuery = NSMutableDictionary(
            objects: [kSecClassGenericPasswordValue, service, key],
            forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue]
        )
        
        guard SecItemCopyMatching(keychainDuplicateQuery, nil) != errSecSuccess else {
            updateData(key: key, data: data)
            return
        }
        
        do {
            let encodedData = try encoder.encode([data])

            let keychainQuery = NSMutableDictionary(
                objects: [kSecClassGenericPasswordValue, service, key, encodedData],
                forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecValueDataValue]
            )
            
            
            // Add the new keychain item
            let status = SecItemAdd(keychainQuery as CFDictionary, nil)
            
            if (status != errSecSuccess) {    // Always check the status
                if let err = SecCopyErrorMessageString(status, nil) {
                    print("Keychain save failed: \(err)")
                }
            }
        } catch {
            print("Keychain save failed: \(error)")
        }
        

    }
    
    /// Update  private data for key
    /// - Parameter key: Data key
    /// - Parameter data: Private data
    class func updateData<T>(key: String, data: T) where T: Encodable{
        
        let keychainQuery = NSMutableDictionary(
            objects: [kSecClassGenericPasswordValue, service, key],
            forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue]
        )
        
        do {
            let encodedData = try encoder.encode([data])
            
            let status = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataValue:encodedData] as CFDictionary)
            
            if (status != errSecSuccess) {
                if let err = SecCopyErrorMessageString(status, nil) {
                    print("Keychain update failed: \(err)")
                }
            }
        } catch {
            print("Keychain update failed: \(error)")
        }
        
    }
    
    /// Load  private data for key
     /// - Parameter key: Data key
    class func loadData<T>(key: String, type: T.Type) -> T? where T: Decodable {

        // Tell the query to return a result
        // Limit our results to one item
        let keychainQuery: NSMutableDictionary = NSMutableDictionary(
            objects: [kSecClassGenericPasswordValue,service,key, kCFBooleanTrue!, kSecMatchLimitOneValue],
            forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue]
        )
        
        var dataTypeRef :AnyObject?
        
        // Search for the keychain items
        SecItemCopyMatching(keychainQuery, &dataTypeRef)
        
        do {
            if let data = dataTypeRef as? Data {
                return try decoder.decode([T].self, from: data).first
            } else {
                return nil
            }
            
        } catch {
            print("Failed to decode data")
            return nil
        }

    }
    
    /// Delete private data for key
    /// - Parameter key: Data key
    class func removeData(key: String) {
        
        let keychainQuery = NSMutableDictionary(
            objects: [kSecClassGenericPasswordValue, service, key, kCFBooleanTrue!],
            forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue]
        )
        
        // Delete any existing items
        let status = SecItemDelete(keychainQuery as CFDictionary)
        if (status != errSecSuccess) {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Keychain remove failed: \(err)")
            }
        }
    }
    
    class func removeAllApplicationData(){
        
        let secItemClasses =  [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }
    }
    
}
