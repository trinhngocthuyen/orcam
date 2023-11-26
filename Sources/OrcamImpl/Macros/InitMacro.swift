import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

public struct InitMacro: BaseMemberMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext,
    arguments: [String: Any]
  ) throws -> [DeclSyntax] {
    try declaration.expectKind(.classDecl, .structDecl)
    let group = DeclGroup(declaration)
    let attribute = try node.asMacroAttribute
    let defaultForOptional = (arguments["defaultForOptional"] as? Bool) ??
      attribute.argument(labeled: "defaultForOptional")?.asBooleanLiteral?.value ?? true
    let accessLevel = (arguments["accessLevel"] as? String) ??
      attribute.argument(labeled: "accessLevel")?.asStringLiteral?.value ?? group.accessLevel

    let propertyWrapperVariables = group.variables.filter(\.isPropertyWrapper).flatMap(\.identifiers)
    let parameters = group.variables
      .filter { $0.isStoredProperty && !$0.isConstant }
      .flatMap {
        $0.bindings.compactMap { binding in
          let parameter = binding.asFunctionParameter?.withoutTrivia().withEscapingAttribute
          return defaultForOptional ? parameter?.withDefaultValueForOptional : parameter
        }
      }
    let initDeclSyntax = try InitializerDeclSyntax("init()") {
      for parameter in parameters {
        if propertyWrapperVariables.contains(parameter.name) {
          "self._\(raw: parameter.name) = .init(wrappedValue: \(raw: parameter.name))"
        } else {
          "self.\(raw: parameter.name) = \(raw: parameter.name)"
        }
      }
    }
    .withParameters(parameters)
    .withAccessLevel(accessLevel)
    return [
      initDeclSyntax.asDeclSyntax,
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try expansion(
      of: node,
      providingMembersOf: declaration,
      in: context,
      arguments: [:]
    )
  }
}
