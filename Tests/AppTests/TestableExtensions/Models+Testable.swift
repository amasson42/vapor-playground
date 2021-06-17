@testable import App
import Fluent

extension User {
    static func create(name: String = "Luke",
                       username: String = "lukes",
                       on database: Database) throws -> User {
        let user = User(name: name, username: username)
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

extension Category {
    static func create(name: String = "Random",
                       on database: Database) throws -> Category {
        let category = Category(name: name)
        try category.save(on: database).wait()
        return category
    }
}
