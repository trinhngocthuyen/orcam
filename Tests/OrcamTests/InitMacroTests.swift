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
        var x: Int = 0 {
          didSet { }
        }
        var y: Bool { false }
        let z: Int = 0
        let completion: () -> Void
      }
      """,
      expandedSource:
      """
      class Foo {
        var x: Int = 0 {
          didSet { }
        }
        var y: Bool { false }
        let z: Int = 0
        let completion: () -> Void

        init(
          x: Int,
          completion: @escaping () -> Void
        ) {
          self.x = x
          self.completion = completion
        }
      }
      """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDefaultForOptional() {
    assertMacroExpansion(
      """
      @Init
      class Foo {
        let x: Double?
        let y: Optional<Double>
      }
      """,
      expandedSource:
      """
      class Foo {
        let x: Double?
        let y: Optional<Double>

        init(
          x: Double? = nil,
          y: Optional<Double> = nil
        ) {
          self.x = x
          self.y = y
        }
      }
      """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )

    assertMacroExpansion(
      """
      @Init(defaultForOptional: false)
      class Foo {
        let x: Double?
        let y: Optional<Double>
      }
      """,
      expandedSource:
      """
      class Foo {
        let x: Double?
        let y: Optional<Double>

        init(
          x: Double?,
          y: Optional<Double>
        ) {
          self.x = x
          self.y = y
        }
      }
      """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }
}

