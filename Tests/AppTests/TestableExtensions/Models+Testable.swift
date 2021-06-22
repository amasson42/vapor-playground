@testable import App
import Fluent
import Vapor

extension User {
    static func create(name: String = "Luke",
                       username: String? = nil,
                       password: String = "password",
                       on database: Database) throws -> User {
        
        let username = username ?? UUID().uuidString
        
        let password = try Bcrypt.hash(password)
        
        let user = User(name: name,
                        username: username,
                        password: password)
        
        try user.save(on: database).wait()
        return user
    }
}

extension Acronym {
    static func create(short: String = "TIL",
                       long: String = "Today I learned",
                       user: User? = nil,
                       on database: Database) throws -> Acronym {
        let acronymUser = try user ?? User.create(on: database)
        
        let acronym = Acronym(short: short, long: long, userID: acronymUser.id!)
        
        try acronym.save(on: database).wait()
        return acronym
    }
}

extension App.Category {
    static func create(name: String = "Random",
                       on database: Database) throws -> App.Category {
        let category = Category(name: name)
        try category.save(on: database).wait()
        return category
    }
}
