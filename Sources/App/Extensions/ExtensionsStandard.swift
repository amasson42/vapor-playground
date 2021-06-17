import Foundation

public extension FileManager {
    
    func directoryExists(atPath path: String) -> Bool {
        var isDir: ObjCBool = true
        let exist = self.fileExists(atPath: path, isDirectory: &isDir)
        return exist && isDir.boolValue
    }
    
    private static var _tmpDirHash = 0
    private static var tmpDirHash: Int { _tmpDirHash += 1; return _tmpDirHash }
    
    func withTemporaryDirectory<Return: Any>(_ exec: () throws -> Return) rethrows -> Return {
        let mainPwd = self.currentDirectoryPath
        let tmpDirUrl: URL
        let tmpName = ProcessInfo.processInfo.globallyUniqueString + "_tmp\(abs(Self.tmpDirHash.hashValue))"
        if #available(macOS 10.12, *) {
            tmpDirUrl = self.temporaryDirectory.appendingPathComponent(tmpName)
        } else {
            tmpDirUrl = URL(string: "/tmp/\(tmpName)")!
        }
        defer {
            self.changeCurrentDirectoryPath(mainPwd)
            try? self.removeItem(at: tmpDirUrl)
        }
        try? self.createDirectory(at: tmpDirUrl, withIntermediateDirectories: true, attributes: nil)
        self.changeCurrentDirectoryPath(tmpDirUrl.path)
        return try exec()
    }
    
}


// MARK: Shell
public enum ShellInput {
    case pipe(Pipe)
    case fileHandle(FileHandle)
    
    @available(*, unavailable, message: "Not implemented yet")
    static func string(_ str: String) -> ShellInput {
        // TODO: find a trick to use a string as standard input
        fatalError("ShellInput from string is not implemented yet")
    }
    
    var asAny: Any {
        switch self {
        case .pipe(let p): return p
        case .fileHandle(let fh): return fh
        }
    }
}

public typealias ShellResult = (stdout: String, stderr: String, code: Int32)

/// Asyncronously start a shell command
/// - Parameters:
///   - command: The command to run in specified shell format
///   - shellPath: Path to the executable shell (default is /bin/bash)
///   - stdin: The standard input send with the command
///   - completion: The completion handler called after the
/// - Throws: Unix error occuring during process
/// - Returns: The `Process` instance that will execute the command.
/// To simplify syncronous call with the syntax
/// `shell("sleep 1; echo hello world").waitUntilExit()`
@discardableResult
public func shell(_ command: String, shellPath: String = "/bin/bash", stdin: ShellInput? = nil, completion: ((ShellResult) -> ())? = nil) throws -> Process {
    let task = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    
    task.standardOutput = stdoutPipe
    task.standardError = stderrPipe
    task.standardInput = stdin?.asAny
    task.arguments = ["-c", command]
    
    #if os(OSX)
    if #available(OSX 10.13, *) {
        task.executableURL = URL(fileURLWithPath: shellPath)
        try task.run()
    } else {
        task.launchPath = shellPath
        task.launch()
    }
    #elseif os(Linux)
    task.executableURL = URL(fileURLWithPath: shellPath)
    try task.run()
    #endif
    
    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    let stdout = String(data: stdoutData, encoding: .utf8)!
    let stderr = String(data: stderrData, encoding: .utf8)!
    
    task.terminationHandler = { process in
        completion?((stdout, stderr, task.terminationStatus))
    }
    
    return task
}
