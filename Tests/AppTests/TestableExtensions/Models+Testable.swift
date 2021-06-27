@testable import App
import Fluent
import Vapor

extension User {
    static func create(name: String = "Luke",
                       username: String? = nil,
                       password: String = "password",
                       userType: UserType = .standard,
                       on database: Database) throws -> User {
        
        let username = username ?? UUID().uuidString
        
        let password = try Bcrypt.hash(password)
        
        let user = User(name: name,
                        username: username,
                        password: password,
                        email: "\(username)@whatever.yolo",
                        twitterUrl: "@\(username)")
        
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

extension App.Pokemon {
    static func create(name: String = "Pikachu",
                       on database: Database) throws -> App.Pokemon {
        let pokemon = Pokemon(name: name)
        try pokemon.save(on: database).wait()
        return pokemon
    }
}

extension App.Todo {
    static func create(title: String = "Kill crew members",
                       on database: Database) throws -> App.Todo {
        let todo = Todo(title: title)
        try todo.save(on: database).wait()
        return todo
    }
}
