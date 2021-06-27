@testable import App
import XCTVapor

final class CategoryTests: XCTestCase {
    
    var app: Application!
    let categoriesURI = "/api/v1/categories/"
    let categoryName = "Teenager"
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app?.shutdown()
    }
    
    func testCategoriesCanBeRetrievedFromAPI() throws {
        let category = try App.Category.create(name: categoryName, on: app.db)
        _ = try App.Category.create(on: app.db)
        
        try app.test(.GET, categoriesURI, afterResponse: { response in
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, 2)
            XCTAssertEqual(categories[0].name, categoryName)
            XCTAssertEqual(categories[0].id, category.id)
        })
    }
    
    func testCategoryCanBeSavedWithAPI() throws {
        let category = Category(name: categoryName)
        
        try app.test(
            .POST, categoriesURI,
            loggedInRequest: true,
            beforeRequest: { request in
            try request.content.encode(category)
        }, afterResponse: { response in
            let receivedCategory = try response.content.decode(App.Category.self)
            XCTAssertEqual(receivedCategory.name, categoryName)
            XCTAssertNotNil(receivedCategory.id)
            
            try app.test(
                .GET, categoriesURI,
                afterResponse: { response in
                let categories = try response.content.decode([App.Category].self)
                XCTAssertEqual(categories.count, 1)
                XCTAssertEqual(categories[0].name, categoryName)
                XCTAssertEqual(categories[0].id, receivedCategory.id)
            })
        })
    }
    
    func testGettingASingleCategoryFromTheAPI() throws {
        let category = try App.Category.create(name: categoryName, on: app.db)
        
        try app.test(
            .GET, "\(categoriesURI)\(category.id!)",
            loggedInRequest: true,
            afterResponse: { response in
                let returnedCategory = try response.content.decode(App.Category.self)
            XCTAssertEqual(returnedCategory.name, categoryName)
            XCTAssertEqual(returnedCategory.id, category.id)
        })
    }
    
    func testGettingACategoriesAcronymsFromTheAPI() throws {
        
        let acronym0 = try Acronym.create(short: "OMG",
                                          long: "Oh My God",
                                          on: app.db)
        let acronym1 = try Acronym.create(on: app.db)
        
        let category = try App.Category.create(name: categoryName, on: app.db)
        
        try app.test(
            .POST, "/api/v1/acronyms/\(acronym0.id!)/categories/\(category.id!)",
            loggedInRequest: true)
        try app.test(
            .POST, "/api/v1/acronyms/\(acronym1.id!)/categories/\(category.id!)",
            loggedInRequest: true)
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)/acronyms", afterResponse: { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 2)
            
            if acronyms.count == 2 {
                XCTAssertEqual(acronyms[0].id, acronym0.id)
                XCTAssertEqual(acronyms[0].short, acronym0.short)
                XCTAssertEqual(acronyms[0].long, acronym0.long)
                
                XCTAssertEqual(acronyms[1].id, acronym1.id)
                XCTAssertEqual(acronyms[1].short, acronym1.short)
                XCTAssertEqual(acronyms[1].long, acronym1.long)
            }
        })
    }

    func testCategoriesGetAll() throws {

        let users: [App.User] = try [
            User.create(name: "Jean", username: "jean", on: app.db),
            User.create(name: "Pierre", username: "pierre", on: app.db)
        ]

        let categoryNames = ["Trading", "Gaming"]
        let categories: [App.Category] = try categoryNames.map {
            try Category.create(name: $0, on: app.db)
        }

        let acronyms: [App.Acronym] = try [
            Acronym.create(
                short: "WTS", long: "Want To Sell",
                user: users[0], on: app.db),
            Acronym.create(
                short: "WTB", long: "Want To Buy",
                user: users[1], on: app.db),
            Acronym.create(
                short: "LFG", long: "Look For Group",
                user: users[0], on: app.db)
        ]

        try acronyms[0].$categories.attach(categories[0], on: app.db).wait()
        try acronyms[1].$categories.attach(categories[0], on: app.db).wait()
        try acronyms[2].$categories.attach(categories[1], on: app.db).wait()

        try app.test(
            .GET, "\(categoriesURI)all",
            afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let allCategories = try response.content.decode([App.CategoriesController.CategoryWithAcronyms].self)

                XCTAssertEqual(allCategories.count, categories.count)
                guard allCategories.count == categories.count else {
                    return
                }
                for i in 0 ..< allCategories.count {
                    XCTAssertEqual(allCategories[i].id, categories[i].id)
                    XCTAssertEqual(allCategories[i].name, categories[i].name)
                }
                XCTAssertEqual(allCategories[0].acronyms.count, 2)
                XCTAssertEqual(allCategories[1].acronyms.count, 1)
                guard allCategories[0].acronyms.count == 2,
                    allCategories[1].acronyms.count == 1 else {
                        return
                    }
                XCTAssertEqual(allCategories[0].acronyms[0].id, acronyms[0].id)
                XCTAssertEqual(allCategories[0].acronyms[0].user.id, users[0].id)

                XCTAssertEqual(allCategories[0].acronyms[1].id, acronyms[1].id)
                XCTAssertEqual(allCategories[0].acronyms[1].user.id, users[1].id)

                XCTAssertEqual(allCategories[1].acronyms[0].id, acronyms[2].id)
                XCTAssertEqual(allCategories[1].acronyms[0].user.id, users[0].id)
                
            })
    }
}
