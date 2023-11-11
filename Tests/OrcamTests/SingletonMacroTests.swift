import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import OrcamImpl

final class SingletonMacroTests: XCTestCase {
  private var testMacros: [String: Macro.Type] { ["Singleton": SingletonMacro.self] }

  func testMacro() {
    assertMacroExpansion(
      """
      @Singleton
      class Foo {
      }
      """,
      expandedSource:
      """
      class Foo {

        static let shared = Foo()

        private init(

        ) {
        }
      }
      """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testMacroWithPredefinedShared() {
    assertMacroExpansion(
      """
      @Singleton
      class Foo {
        static let shared = Foo()
      }
      """,
      expandedSource:
      """
      class Foo {
        static let shared = Foo()

        private init(

        ) {
        }
      }
      """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }
}

