import SwiftUI
import Orcam

// MARK: @Init

// -------------------------------------------
do {
  @Init
  struct Foo {
    let x: Int
    let y: Int = 0
    // swiftformat:disable:next typeSugar
    let z: Optional<Int>
    let completion: () -> Void
  }

  _ = Foo(x: 0) {}

  @Init
  struct Container {
    final class VM: ObservableObject {}

    @State var x: Int
    @StateObject var vm: VM
  }

  _ = Container(x: 0, vm: .init())
}

// MARK: @Singleton

// -------------------------------------------
do {
  @Singleton
  class Service {}

  _ = Service.shared
}

// MARK: @Copyable

do {
  @Copyable
  struct Foo {
    let x: Int
    let y: Int?
  }

  _ = Foo(x: 0, y: 0).copy()
}
