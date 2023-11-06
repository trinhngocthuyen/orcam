import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import OrcamMacros

let testMacros: [String: Macro.Type] = [
  "Init": InitMacro.self
]

final class InitMacroTests: XCTestCase {
  func testMacroForClass() {
    assertMacroExpansion(
      """
      @Init
      class Foo {
        var x: Int {
          didSet { }
        }
        let y: Double?
        let yy: Optional<Double>
        var z: Bool { false }
        let completion: () -> Void
      }
      """,
      expandedSource:
      """
      class Foo {
        var x: Int {
          didSet { }
        }
        let y: Double?
        let yy: Optional<Double>
        var z: Bool { false }
        let completion: () -> Void

        init(
          x: Int,
          y: Double?,
          yy: Optional<Double>,
          completion: () -> Void
        ) {
          self.x = x
          self.y = y
          self.yy = yy
          self.completion = completion
        }
      }
      """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }
}

