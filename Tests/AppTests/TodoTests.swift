@testable import App
import XCTVapor

final class TodoTests: XCTestCase {
    
    var app: Application!
    let todosURI = "/todos/"
    let todoTitle = "Do the tasks"
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app?.shutdown()
    }
    
    func testTodosCanBeRetrieved() throws {
        let todo0 = try Todo.create(title: todoTitle, on: app.db)
        let todo1 = try Todo.create(on: app.db)
        
        try app.test(
            .GET, todosURI,
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: Environment.tilEnv.X_SECRET)
            },
            afterResponse: { response in
                let todos = try response.content.decode([Todo].self)
                
                XCTAssertEqual(todos.count, 2)
                
                XCTAssertEqual(todos[0].title, todo0.title)
                XCTAssertEqual(todos[0].id, todo0.id)
                
                XCTAssertEqual(todos[1].title, todo1.title)
                XCTAssertEqual(todos[1].id, todo1.id)
            })
    }
    
    func testTodoCanBeSaved() throws {
        
        let createTodoData = ["title": todoTitle]
        
        try app.test(
            .POST, todosURI,
            beforeRequest: { request in
                try request.content.encode(createTodoData)
                request.headers.add(name: .xSecret, value: Environment.tilEnv.X_SECRET)
            }, afterResponse: { response in
                let receivedTodo = try response.content.decode(Todo.self)
                XCTAssertEqual(receivedTodo.title, todoTitle)
                XCTAssertNotNil(receivedTodo.id)
                
                try app.test(
                    .GET, todosURI,
                    beforeRequest: { request in
                        request.headers.add(name: .xSecret, value: Environment.tilEnv.X_SECRET)
                    },
                    afterResponse: { allTodosResponse in
                        let todos = try allTodosResponse.content.decode([Todo].self)
                        XCTAssertEqual(todos.count, 1)
                        
                        if todos.count == 1 {
                            XCTAssertEqual(todos[0].title, todoTitle)
                            XCTAssertEqual(todos[0].id, receivedTodo.id)
                        }
                        
                    })
            })
    }
    
    func testGettingASingleTodo() throws {
        let todo = try Todo.create(title: todoTitle, on: app.db)
        
        try app.test(
            .GET, "\(todosURI)\(todo.id!)",
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: Environment.tilEnv.X_SECRET)
            },
            afterResponse: { response in
                print("status:", response.status)
                let returnedTodo = try response.content.decode(Todo.self)
                XCTAssertEqual(returnedTodo.title, todo.title)
            })
    }
    
    func testDeletingATodo() throws {
        let todo = try Todo.create(on: app.db)
        
        try app.test(
            .GET, todosURI,
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: Environment.tilEnv.X_SECRET)
            },
            afterResponse: { response in
                let todos = try response.content.decode([Todo].self)
                XCTAssertEqual(todos.count, 1)
            })
        
        try app.test(
            .DELETE, "\(todosURI)\(todo.id!)",
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: Environment.tilEnv.X_SECRET)
            },
            afterResponse: { response in
                XCTAssertEqual(response.status, .noContent)
            })
        
        try app.test(
            .GET, todosURI,
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: Environment.tilEnv.X_SECRET)
            },
            afterResponse: { response in
                let newTodos = try response.content.decode([Todo].self)
                XCTAssertEqual(newTodos.count, 0)
            })
    }
    
    func testGetTodosWithWrongOrWithoutSecret() throws {
        _ = try Todo.create(on: app.db)
        
        try app.test(
            .GET, todosURI,
            afterResponse: {
                response in
                XCTAssertEqual(response.status, .unauthorized)
            }
        )
        
        try app.test(
            .GET, todosURI,
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: "wrong-secret")
            },
            afterResponse: {
                response in
                XCTAssertEqual(response.status, .unauthorized)
            }
        )
        
    }
    
    func testPostTodoWithWrongOrWithoutSecret() throws {
        
        let createTodoData = ["title": todoTitle]
        
        try app.test(
            .POST, todosURI,
            beforeRequest: { request in
                try request.content.encode(createTodoData)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .unauthorized)
            })
        
        try app.test(
            .POST, todosURI,
            beforeRequest: { request in
                try request.content.encode(createTodoData)
                request.headers.add(name: .xSecret, value: "wrong-secret")
            },
            afterResponse: {
                response in
                XCTAssertEqual(response.status, .unauthorized)
            })
        
    }
    
    func testGetTodoWithWrongOrWithoutSecret() throws {
        let todo = try Todo.create(on: app.db)
        
        try app.test(
            .GET, "\(todosURI)\(todo.id!)",
            afterResponse: {
                response in
                XCTAssertEqual(response.status, .unauthorized)
            }
        )
        
        try app.test(
            .GET, "\(todosURI)\(todo.id!)",
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: "wrong-secret")
            },
            afterResponse: {
                response in
                XCTAssertEqual(response.status, .unauthorized)
            }
        )
        
    }
    
    func testDeleteTodosWithWrongOrWithoutSecret() throws {
        let todo = try Todo.create(on: app.db)
        
        try app.test(
            .DELETE, "\(todosURI)\(todo.id!)",
            afterResponse: {
                response in
                XCTAssertEqual(response.status, .unauthorized)
            }
        )
        
        try app.test(
            .DELETE, "\(todosURI)\(todo.id!)",
            beforeRequest: { request in
                request.headers.add(name: .xSecret, value: "wrong-secret")
            },
            afterResponse: {
                response in
                XCTAssertEqual(response.status, .unauthorized)
            }
        )
        
    }
    
}
