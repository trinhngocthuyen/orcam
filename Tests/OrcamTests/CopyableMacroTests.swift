import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import OrcamImpl

final class CopyableMacroTests: BaseMacroTests {
  func testMacro() {
    assertMacroExpansion(
      """
      @Copyable
      struct Foo {
        let x: Int
        let y: Double
      }
      """,
      expandedSource:
      """
      struct Foo {
        let x: Int
        let y: Double

        func copy(update_x: ((Int) -> Int)? = nil, update_y: ((Double) -> Double)? = nil) -> Self {
          func call<V>(_ f: ((V) -> V)?, _ v: V) -> V {
            f?(v) ?? v
          }
          return .init(x: call(update_x, self.x), y: call(update_y, self.y))
        }
      }
      """
    )
  }
}
