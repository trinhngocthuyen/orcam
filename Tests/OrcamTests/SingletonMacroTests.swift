import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import OrcamImpl

final class SingletonMacroTests: BaseMacroTests {
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
      """
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
      """
    )
  }
}
