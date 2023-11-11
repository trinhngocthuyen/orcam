import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

public struct InitMacro: BaseMemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try declaration.expectKind(.classDecl, .structDecl)
    let group = DeclGroup(declaration)
    let attribute = try node.asMacroAttribute
    let defaultForOptional = attribute.argument(labeled: "defaultForOptional")?.asBooleanLiteral?.value ?? true

    func makeHeader(for binding: VariableBinding) -> String? {
      guard let identifier = binding.identifier, let type = binding.type else { return nil }
      if type.asFunctionType != nil {
        return "\(identifier): @escaping \(type.description)"
      }
      if defaultForOptional, type.isOptional {
        return "\(identifier): \(type.description) = nil"
      }
      return "\(identifier): \(type.description)"
    }

    func makeBody(for binding: VariableBinding) -> String? {
      guard let identifier = binding.identifier, let type = binding.type else { return nil }
      return "self.\(identifier) = \(identifier)"
    }

    let literals = group.variables.flatMap { variable -> [(String, String)] in
      guard variable.isStoredProperty, !variable.isConstant else { return [] }
      return variable.bindings.compactMap { zip(makeHeader(for: $0), makeBody(for: $0)) }
    }
    return try [
      InitializerDeclSyntax(
        accessLevel: group.accessLevel,
        literals: literals
      ).asDeclSyntax
    ]
  }
}
