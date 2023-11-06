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
        @StateObject var a: Int
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
        @StateObject var a: Int
        let completion: () -> Void

        public init(
          x: Int,
          y: Double? = nil,
          yy: Optional<Double> = nil,
          a: Int,
          completion: @escaping () -> Void
        ) {
          self.x = x
          self.y = y
          self.yy = yy
          self._a = .init(wrappedValue: a)
          self.completion = completion
        }
      }
      """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }
}

