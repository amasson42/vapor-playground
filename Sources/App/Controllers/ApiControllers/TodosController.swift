import Vapor
import Fluent

struct TodosController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("todos")
        
        group.get(use: handleGet)
        group.post(use: handlePost)
        group.get(":id", use: handleGetOne)
        group.delete(":id", use: handleDelete)
    }
    
    func handleGet(_ req: Request) -> EventLoopFuture<[Todo]> {
        return Todo.query(on: req.db).all()
    }
    
    func handlePost(_ req: Request) throws -> EventLoopFuture<Todo> {
        let todo = try req.content.decode(Todo.self)
        return todo.create(on: req.db)
            .transform(to: todo)
    }
    
    func handleGetOne(_ req: Request) throws -> EventLoopFuture<Todo> {
        Todo.find(req.parameters.get("id"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func handleDelete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Todo.find(req.parameters.get("id"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .noContent)
    }
    
}
