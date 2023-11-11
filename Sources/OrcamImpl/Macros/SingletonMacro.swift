import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

public struct SingletonMacro: BaseMemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    

    return [
      try InitializerDeclSyntax(
        accessLevel: "private",
        literals: []
      ).asDeclSyntax,
    ]
  }
}
