import Vapor
import FluentPostgresDriver

struct TILEnv {
    
    let DATABASE_HOST: String
    let DATABASE_PORT: Int
    let DATABASE_USERNAME: String
    let DATABASE_PASSWORD: String
    let DATABASE_NAME: String
    
    struct MissingKeysError: Error {
        let keys: [String]
    }
    
    init() throws {
        var missingRequiredKeys: [String] = []
        func getRequired(_ key: String) -> String {
            if let value = Environment.get(key) {
                return value
            } else {
                missingRequiredKeys.append(key)
                return ""
            }
        }
        func getDefault(_ key: String, def: String) -> String {
            return Environment.get(key) ?? def
        }
        func getDefault(_ key: String, def: Int) -> Int {
            return Environment.get(key)?.toInt ?? def
        }
        func getOptionnal(_ key: String, message: String? = nil) -> String? {
            let value = Environment.get(key)
            if value == nil, let message = message {
                print("Missing environment key \"\(key)\": \(message)")
            }
            return value
        }
        
        self.DATABASE_HOST = getDefault("DATABASE_HOST", def: "localhost")
        self.DATABASE_PORT = getDefault("DATABASE_PORT", def: PostgresConfiguration.ianaPortNumber)
        self.DATABASE_USERNAME = getDefault("DATABASE_USERNAME", def: "vapor_username")
        self.DATABASE_PASSWORD = getDefault("DATABASE_PASSWORD", def: "vapor_password")
        self.DATABASE_NAME = getDefault("DATABASE_NAME", def: "vapor_database")
        
        if !missingRequiredKeys.isEmpty {
            throw MissingKeysError(keys: missingRequiredKeys)
        }
    }
}

extension Environment {
    static let tilEnv: TILEnv = {
        do {
            return try TILEnv()
        } catch {
            fatalError("\(error)")
        }
    }()
}
