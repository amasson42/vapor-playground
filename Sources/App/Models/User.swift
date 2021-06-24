import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "email")
    var email: String
    
    @OptionalField(key: "profilePicture")
    var profilePicture: String?
    
    @Children(for: \.$user)
    var acronyms: [Acronym]
    
    init() {}
    
    init(id: UUID? = nil, name: String,
         username: String, password: String,
         email: String, profilePicture: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        self.email = email
        self.profilePicture = profilePicture
    }
    
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
    
    func `public`() -> Public {
        .init(id: self.id, name: self.name, username: self.username)
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
