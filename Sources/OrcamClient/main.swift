import SwiftUI
import Orcam

@Init
struct Foo {
  let x: Int
  let y: Int = 0
  let z: Optional<Int>
  let completion: () -> Void
}

// let foo = Foo(x: 0, y: 0)

@Singleton
class Service {
}

//let service = Service.shared
