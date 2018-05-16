import RxSwift

class Project {
    private let developerSubject = PublishSubject<Developer>()
    var developerStream: Observable<Developer> {
        return developerSubject.asObservable()
    }
    
    func addDeveloper(_ developer: Developer) {
        developerSubject.onNext(developer)
    }
    
    func stop() {
        developerSubject.onCompleted()
    }
}

class Developer {
    private let commitSubject = PublishSubject<Commit>()
    let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    func startCoding() -> Observable<Commit> {
        return commitSubject.asObservable()
    }
    
    func stopCoding() {
        commitSubject.onCompleted()
    }
    
    // Helper to externally simulate coding activity.
    func pushCommit(_ hash: String) {
        commitSubject.onNext(Commit(author: name, hash: hash))
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

////////////////////////////////////////////////////////
// Setup

let project = Project()
let jim = Developer("Jim")
let anna = Developer("Anna")
let bob = Developer("Bob")
let ci = CI()

project.developerStream
    .flatMap { developer -> Observable<Commit> in
        print("\(developer.name) started coding...")
        return developer.startCoding()
    }
    .subscribe(ci)

////////////////////////////////////////////////////////////
// Normal operation

project.addDeveloper(jim)  // Jim started coding...
jim.pushCommit("1")        // CI is building Commit(author: "Jim", hash: "1").
project.addDeveloper(anna) // Anna started coding...
anna.pushCommit("1")       // CI is building Commit(author: "Anna", hash: "1").
jim.pushCommit("2")        // CI is building Commit(author: "Jim", hash: "2").

/////////////////////////////////////////////////////////////
// project completion

//project.stop()
//project.addDeveloper(bob)
//bob.pushCommit("1")
//jim.pushCommit("3")       // CI is building Commit(author: "Jim", hash: "3").

/////////////////////////////////////////////////////////////
// Developer completion

//jim.stopCoding()
//anna.stopCoding()
//jim.pushCommit("3")
//project.addDeveloper(bob) // Bob started coding...
//bob.pushCommit("1")       // CI is building Commit(author: "Bob", hash: "1").

/////////////////////////////////////////////////////////////
// ci completion

project.stop()
anna.stopCoding()
jim.stopCoding()          // CI stopped.
project.addDeveloper(bob)
bob.pushCommit("1")
jim.pushCommit("1")
