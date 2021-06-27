import Vapor
import Fluent
import Foundation

enum UserType: String, CaseIterable, Codable {
    case admin
    case standard
    case restricted
}

final class User: Model, Content {
    static let schema = v100.schema
    
    @ID
    var id: UUID?
    
    @Field(key: v100.name)
    var name: String
    
    @Field(key: v100.username)
    var username: String
    
    @Field(key: v100.password)
    var password: String
    
    @Field(key: v100.email)
    var email: String

    @Enum(key: v120.userType)
    var userType: UserType
    
    @OptionalField(key: v110.twitterUrl)
    var twitterUrl: String?
    
    @OptionalField(key: v100.profilePicture)
    var profilePicture: String?
    
    @Children(for: \.$user)
    var acronyms: [Acronym]
    
    @Timestamp(key: v120.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: v120.deletedAt, on: .delete)
    var deletedAt: Date?

    init() {}
    
    init(id: UUID? = nil, name: String,
         username: String, password: String,
         email: String,
         userType: UserType = .standard,
         twitterUrl: String? = nil, profilePicture: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        self.email = email
        self.userType = userType
        self.twitterUrl = twitterUrl
        self.profilePicture = profilePicture
    }
    
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        var twitterUrl: String?
        
        init(id: UUID?, name: String, username: String, twitterUrl: String?) {
            self.id = id
            self.name = name
            self.username = username
            self.twitterUrl = twitterUrl
        }
    }
    
    func `public`() -> Public {
        .init(id: self.id, name: self.name, username: self.username, twitterUrl: self.twitterUrl)
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey = \User.$username
    
    static var passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
    
}

extension User: ModelSessionAuthenticatable {}

extension User: ModelCredentialsAuthenticatable {}
