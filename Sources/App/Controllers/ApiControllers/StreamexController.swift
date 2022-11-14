import Vapor
import Fluent

struct StreamexController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("streamex")

        group.on(.POST, "postfile", body: .stream, use: postFile)
        group.on(.POST, "postcsv", body: .stream, use: postCsv)
    }

    func postFile(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        struct Input: Content {
            var file: File
        }

        // [Warning]: Content.decode can take a long time in debug build
        // let filename = try req.content.decode(Input.self).file.filename
        let filename = "streamed_data"

        let path = req.application.directory.publicDirectory + filename

        var handlers: [EventLoopFuture<Void>] = []

        return req.application.fileio.openFile(path: path, mode: .write, flags: .allowFileCreation(), eventLoop: req.eventLoop)
            .flatMap { handle -> EventLoopFuture<HTTPStatus> in
                let promise = req.eventLoop.makePromise(of: Void.self)

                req.body.drain { stream in
                    switch stream {
                    case .buffer(let bytes):
                        let handler = req.application.fileio.write(fileHandle: handle, buffer: bytes, eventLoop: req.eventLoop)
                        handlers.append(handler)
                        return handler
                    case .end:
                        promise.succeed(())
                        return req.eventLoop.makeSucceededVoidFuture()
                    case .error(let error):
                        promise.fail(error)
                        return req.eventLoop.makeFailedFuture(error)
                    }
                }

                return promise.futureResult.flatMap { () -> EventLoopFuture<Void> in
                    handlers.flatten(on: req.eventLoop)
                }.always { result in
                    do {
                        try handle.close()

                        if case .failure = result {
                            try FileManager.default.removeItem(atPath: path)
                        }
                    } catch {
                        req.logger.critical("Upload cleanup error: \(error)")
                    }
                }.transform(to: .ok)
            }
    }

    func postCsv(_ req: Request) -> EventLoopFuture<[[String]]> {
        struct Input: Content {
            var file: File
        }

        // [Warning]: Content.decode can take a long time in debug build
        // let filename = try req.content.decode(Input.self).file.filename
        let filename = "streamed_data"

        let path = req.application.directory.publicDirectory + filename

        var bigCsvValues: [[String]] = []

        return req.application.fileio.openFile(path: path, mode: .write, flags: .allowFileCreation(), eventLoop: req.eventLoop)
            .flatMap { handle -> EventLoopFuture<HTTPStatus> in
                let promise = req.eventLoop.makePromise(of: Void.self)

                req.body.drainLines(eventLoop: req.eventLoop) { line in

                    let lineValues = line.components(separatedBy: ";")

                    /// -> use here the lineValues as the values in your csv
                    bigCsvValues.append(lineValues)

                } endHandler: { r in
                    do {
                        try handle.close()
                        switch r {
                        case .success:
                            promise.succeed(())
                        case .failure(let error):
                            promise.fail(error)
                        }
                    } catch {
                        req.logger.critical("Upload cleanup error: \(error)")
                    }
                }

                return promise.futureResult.transform(to: .ok)
            }
            .map { _ in
                bigCsvValues
            }

    }

}

extension Request.Body {
    func drainLines(eventLoop: EventLoop, lineHandler: @escaping (String) -> (), endHandler: @escaping (Result<Void, Error>) -> ()) {

        var previousLine = ""

        self.drain { stream in
            switch stream {
            case .buffer(let buffer):
                var lines = String(buffer: buffer).components(separatedBy: .newlines)

                guard !lines.isEmpty else {
                    return eventLoop.makeSucceededVoidFuture()
                }

                lines[0] = previousLine + lines[0]

                previousLine = lines.removeLast()

                lines.forEach(lineHandler)

                return eventLoop.makeSucceededVoidFuture()

            case .error(let error):
                endHandler(.failure(error))
                return eventLoop.makeSucceededVoidFuture()
            case .end:
                if !previousLine.isEmpty {
                    lineHandler(previousLine)
                }
                endHandler(.success(()))
                return eventLoop.makeSucceededVoidFuture()
            }
        }
    }
}

