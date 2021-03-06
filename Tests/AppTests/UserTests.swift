@testable import App
import XCTVapor

final class UserTests: XCTestCase {
    
    var app: Application!
    let usersURI = "/api/v1/users/"
    let usersName = "Alice"
    let usersUsername = "alicea"
    let usersTwitterUrl = "@alicea"
    let usersPassword = "securityprofesional"
    let usersEmail = "alicea@whatever.yolo"
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app?.shutdown()
    }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            password: usersPassword,
            on: app.db)
        _ = try User.create(on: app.db)
        
        try app.test(
            .GET, usersURI,
            afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                
                let users = try response.content.decode([User.Public].self)
                
                XCTAssertEqual(users.count, 3)
                XCTAssertEqual(users[1].name, usersName)
                XCTAssertEqual(users[1].username, usersUsername)
                XCTAssertEqual(users[1].id, user.id)
            })
    }
    
    func testUserCanBeSavedWithAPI() throws {
        let user = User(
            name: usersName,
            username: usersUsername,
            password: usersPassword,
            email: usersEmail,
            twitterUrl: usersTwitterUrl)
        
        try app.test(
            .POST, usersURI,
            loggedInRequest: true,
            beforeRequest: { req in
                try req.content.encode(user)
            }, afterResponse: { response in
                let receivedUser = try response.content.decode(User.Public.self)
                
                XCTAssertEqual(receivedUser.name, usersName)
                XCTAssertEqual(receivedUser.username, usersUsername)
                XCTAssertNotNil(receivedUser.id)
                
                try app.test(
                    .GET, usersURI,
                    afterResponse: { secondResponse in
                        
                        let users = try secondResponse.content.decode([User.Public].self)
                        XCTAssertEqual(users.count, 2)
                        XCTAssertEqual(users[1].name, usersName)
                        XCTAssertEqual(users[1].username, usersUsername)
                        XCTAssertEqual(users[1].twitterUrl, usersTwitterUrl)
                        XCTAssertEqual(users[1].id, receivedUser.id)
                        
                    })
                
            })
    }
    
    func testGettingSingleUserFromTheApi() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: app.db)
        
        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { response in
                let receivedUser = try response.content.decode(User.Public.self)
                
                XCTAssertEqual(receivedUser.name, usersName)
                XCTAssertEqual(receivedUser.username, usersUsername)
                XCTAssertEqual(receivedUser.id, user.id)
                
            })
    }

    func testDeletingSingleUser() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: app.db)
        
        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })

        try app.test(
            .DELETE, "\(usersURI)\(user.id!)",
            loggedInRequest: true,
            afterResponse: { XCTAssertEqual($0.status, .noContent) })

        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .notFound) })
    }

    func testDeletingAndRestoringSingleUser() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: app.db)
        
        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })

        try app.test(
            .DELETE, "\(usersURI)\(user.id!)",
            loggedInRequest: true,
            afterResponse: { XCTAssertEqual($0.status, .noContent) })

        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .notFound) })
        
        try app.test(
            .POST, "\(usersURI)\(user.id!)/restore",
            loggedInRequest: true,
            afterResponse: { XCTAssertEqual($0.status, .ok) })

        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })
    }
    
    func testForceDeletingUser() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: app.db)
        
        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })

        try app.test(
            .DELETE, "\(usersURI)\(user.id!)/force",
            loggedInRequest: true,
            afterResponse: { XCTAssertEqual($0.status, .noContent) })

        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .notFound) })
        
        try app.test(
            .POST, "\(usersURI)\(user.id!)/restore",
            loggedInRequest: true,
            afterResponse: { XCTAssertEqual($0.status, .notFound) })

        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .notFound) })
    }

    func testDeletingSingleUserForbidden() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: app.db)
        
        let restrictedUser = try User.create(
            name: "Pleb",
            username: "pleb",
            userType: .restricted,
            on: app.db)
        
        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })

        try app.test(
            .DELETE, "\(usersURI)\(user.id!)",
            loggedInUser: restrictedUser,
            afterResponse: { XCTAssertEqual($0.status, .forbidden) })

        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })
    }

    func testDeletingForceSingleUserForbidden() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: app.db)
        
        let restrictedUser = try User.create(
            name: "Pleb",
            username: "pleb",
            userType: .restricted,
            on: app.db)
        
        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })

        try app.test(
            .DELETE, "\(usersURI)\(user.id!)/force",
            loggedInUser: restrictedUser,
            afterResponse: { XCTAssertEqual($0.status, .forbidden) })

        try app.test(
            .GET, "\(usersURI)\(user.id!)",
            afterResponse: { XCTAssertEqual($0.status, .ok) })
    }

    func testGettingAUsersAcronymsFromTheAPI() throws {
        let user = try User.create(on: app.db)
        
        let acronym0 = try Acronym.create(short: "OMG",
                                          long: "Oh My God",
                                          user: user,
                                          on: app.db)
        let acronym1 = try Acronym.create(short: "LOL",
                                          long: "laugh Out Loud",
                                          user: user,
                                          on: app.db)
        
        try app.test(.GET, "\(usersURI)\(user.id!)/acronyms",
                     afterResponse: { response in
                        let acronyms = try response.content.decode([Acronym].self)
                        
                        XCTAssertEqual(acronyms.count, 2)
                        
                        XCTAssertEqual(acronyms[0].id, acronym0.id)
                        XCTAssertEqual(acronyms[0].short, acronym0.short)
                        XCTAssertEqual(acronyms[0].long, acronym0.long)
                        
                        XCTAssertEqual(acronyms[1].id, acronym1.id)
                        XCTAssertEqual(acronyms[1].short, acronym1.short)
                        XCTAssertEqual(acronyms[1].long, acronym1.long)
                     })
    }

    func testGettingMostRecentAcronymUserFromTheApi() throws {
        let user0 = try User.create(on: app.db)
        let user1 = try User.create(on: app.db)
        let user2 = try User.create(on: app.db)

        _ = try Acronym.create(user: user0, on: app.db)
        _ = try Acronym.create(user: user1, on: app.db)
        _ = try Acronym.create(user: user2, on: app.db)

        try app.test(
            .GET, "\(usersURI)mostRecentAcronym",
            afterResponse: { response in
                let user = try response.content.decode(User.Public.self)
                XCTAssertEqual(user.id, user2.id)
            }
        )

        _ = try Acronym.create(user: user1, on: app.db)

        try app.test(
            .GET, "\(usersURI)mostRecentAcronym",
            afterResponse: { response in
                let user = try response.content.decode(User.Public.self)
                XCTAssertEqual(user.id, user1.id)
            }
        )
        
    }
    
}
