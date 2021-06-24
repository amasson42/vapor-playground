import Vapor
import FluentPostgresDriver

struct TILEnv {
    
    let LISTEN_FRONT_URL: String
    
    // MARK: Database connection
    let DATABASE_HOST: String
    let DATABASE_PORT: Int
    let DATABASE_USERNAME: String
    let DATABASE_PASSWORD: String
    let DATABASE_NAME: String
    
    // MARK: Sign in with Google
    let GOOGLE_CALLBACK_URL: String? // http://localhost:8080/oauth/google
    let GOOGLE_CLIENT_ID: String?
    let GOOGLE_CLIENT_SECRET: String?

    // MARK: Sign in with GitHub
    let GITHUB_CALLBACK_URL: String? // http://localhost:8080/oauth/github
    let GITHUB_CLIENT_ID: String?
    let GITHUB_CLIENT_SECRET: String?

    // MARK: SendGrid mailer
    let SENDGRID_API_KEY: String?
    let SENDGRID_SENDER_EMAIL: String?
    
    // MARK: Initialization
    
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
        func getDefaultString(_ key: String, def: String) -> String {
            return Environment.get(key) ?? def
        }
        func getDefaultInt(_ key: String, def: Int) -> Int {
            return Environment.get(key)?.toInt ?? def
        }
        func getOptionnal(_ key: String, message: String? = nil) -> String? {
            let value = Environment.get(key)
            if value == nil, let message = message {
                print("Missing environment key \"\(key)\": \(message)")
            }
            return value
        }
        
        self.LISTEN_FRONT_URL = getDefaultString("LISTEN_FRONT_URL", def: "http://localhost:8080")
        
        self.DATABASE_HOST = getDefaultString("DATABASE_HOST", def: "localhost")
        self.DATABASE_PORT = getDefaultInt("DATABASE_PORT", def: PostgresConfiguration.ianaPortNumber)
        self.DATABASE_USERNAME = getDefaultString("DATABASE_USERNAME", def: "vapor_username")
        self.DATABASE_PASSWORD = getDefaultString("DATABASE_PASSWORD", def: "vapor_password")
        self.DATABASE_NAME = getDefaultString("DATABASE_NAME", def: "vapor_database")
        
        self.GOOGLE_CALLBACK_URL = getOptionnal("GOOGLE_CALLBACK_URL", message: "No Google for you !")
        self.GOOGLE_CLIENT_ID = getOptionnal("GOOGLE_CLIENT_ID")
        self.GOOGLE_CLIENT_SECRET = getOptionnal("GOOGLE_CLIENT_SECRET")
        
        self.GITHUB_CALLBACK_URL = getOptionnal("GITHUB_CALLBACK_URL", message: "No Github for you !")
        self.GITHUB_CLIENT_ID = getOptionnal("GITHUB_CLIENT_ID")
        self.GITHUB_CLIENT_SECRET = getOptionnal("GITHUB_CLIENT_SECRET")
        
        self.SENDGRID_API_KEY = getOptionnal("SENDGRID_API_KEY", message: "No Mailer for you !")
        self.SENDGRID_SENDER_EMAIL = getOptionnal("SENDGRID_SENDER_EMAIL")
        
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
