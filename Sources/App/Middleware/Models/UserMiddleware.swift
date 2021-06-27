import Vapor
import Fluent

struct UserMiddleware: ModelMiddleware {

    func create(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        User.query(on: db)
            .filter(\.$username == model.username)
            .count()
            .flatMap { count in
                guard count == 0 else {
                    let error = Abort(.badRequest, reason: "Username already exists")
                    return db.eventLoop.future(error: error)
                }

                return next.create(model, on: db).map {
                    let errorMessage: Logger.Message = "Created user with username \(model.username)"
                    db.logger.debug(errorMessage)
                }
            }
    }

}
