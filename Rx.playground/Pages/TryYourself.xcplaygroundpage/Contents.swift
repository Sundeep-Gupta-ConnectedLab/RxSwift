import RxSwift

class Project {
    var developerStream: Observable<Developer> {
        return developerSubject.asObservable()
    }
    private let developerSubject = PublishSubject<Developer>()
    
    func addDeveloper(_ developer: Developer) {
        developerSubject.onNext(developer)
    }
    
    func stop() {
        developerSubject.onCompleted()
    }
    
    func error() {
        developerSubject.onError(Errors.projectError)
    }
}

class Developer {
    let name: String
    private let commitSubject = PublishSubject<Commit>()
    
    init(_ name: String) {
        self.name = name
    }
    
    func startCoding() -> Observable<Commit> {
        return commitSubject.asObservable()
    }
    
    func stopCoding() {
        commitSubject.onCompleted()
    }
    
    // Helpers to simulate coding activity.
    
    func pushCommit(_ hash: String) {
        commitSubject.onNext(Commit(author: name, hash: hash))
    }
    
    func pushBrokenBuild() {
        commitSubject.onError(Errors.developerError)
    }
}

struct Commit {
    let author: String
    let hash: String
}

class CI: ObserverType {
    func on(_ event: Event<Commit>) {
        switch event {
        case .next(let commit): print("CI is building \(commit).")
        case .completed: print("CI stopped.")
        case .error(let error): print("CI errored: \(error).")
        }
    }
}

enum Errors: Error {
    case developerError
    case projectError
}

////////////////////////////////////////////////////////
// Setup

let project = Project()
let jim = Developer("Jim")
let anna = Developer("Anna")
let bob = Developer("Bob")
let ci = CI()

project.developerStream
    .debug("developer stream")
    .flatMap { developer -> Observable<Commit> in
        print("\(developer.name) started coding...")
        return developer.startCoding().debug(developer.name)
    }
    .debug("commit stream")
    .subscribe(ci)

////////////////////////////////////////////////////////////
// Normal operation

project.addDeveloper(jim) // Jim started coding...
jim.pushCommit("1") // CI is building Commit(author: "Jim", hash: "1").

project.addDeveloper(anna) // Anna started coding...
anna.pushCommit("1") // CI is building Commit(author: "Anna", hash: "1").

jim.pushCommit("2") // CI is building Commit(author: "Jim", hash: "2").

//////////////////////////////////////////////////////////
// When the project errors, the flatMap and CI stop subscribing.

//project.error() // CI errored: projectError.
//
//jim.pushCommit("3") // (No event is emitted.)
//project.addDeveloper(bob) // (No event is emitted.)
//bob.pushCommit("3") // (No event is emitted.)

/////////////////////////////////////////////////////////////
// When a developer errors, the same thing happens, everything dies.

//jim.pushBrokenBuild() // CI errored: developerError.
//
//anna.pushCommit("2") // (No event is emitted.)
//project.addDeveloper(bob) // (No event is emitted.)
//bob.pushCommit("3") // (No event is emitted.)

/////////////////////////////////////////////////////////////
// project completion

//project.stop()
//project.addDeveloper(Developer("Bob")) // (No event is emitted.)
//jim.pushCommit("3") // CI is building Commit(author: "Jim", hash: "3").

/////////////////////////////////////////////////////////////
// Developer completion

//jim.stopCoding()
//anna.stopCoding()
//
//jim.pushCommit("3") // (No event is emitted.)
//
//project.addDeveloper(bob) // Bob started coding...
//bob.pushCommit("1") // CI is building Commit(author: "Bob", hash: "1").

/////////////////////////////////////////////////////////////
// ci completion

jim.stopCoding()
project.stop()
anna.stopCoding() // CI stopped.

project.addDeveloper(bob) // (No event is emitted.)
bob.pushCommit("1") // (No event is emitted.)
jim.pushCommit("3") // (No event is emitted.)




// MARK: - FlatMapLatest
//developerAdded
//    .flatMapLatest { developer -> Observable<Commit> in
//        return developer.startCoding()
//    }
//    .subscribe(ci)
//
//let jim = Developer(name: "Jim")
//let anna = Developer(name: "Anna")
//
//project.addDeveloper(jim)
//jim.pushCommit("1")
//
//project.addDeveloper(anna)
//jim.pushCommit("2")
//
//
//anna.pushCommit("1")
//
//jim.pushCommit("2")
//
//anna.pushCommit("2")
