import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

public struct InitMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
      throw MacroError("Not a struct or class")
    }
    guard let attribute = Attribute(node).asMacroAttribute else {
      throw MacroError("Cannot cast \(node) to MacroAttribute")
    }

    let group = DeclGroup(declaration)
    let defaultForOptional = attribute.argument(labeled: "defaultForOptional")?.asBooleanLiteral?.value ?? true
    var rawHeaders = [String](), rawBodies = [String]()

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

    for variable in group.variables where variable.isStoredProperty && !variable.isConstant {
      for binding in variable.bindings {
        if let rawHeader = makeHeader(for: binding), let rawBody = makeBody(for: binding) {
          rawHeaders.append(rawHeader)
          rawBodies.append(rawBody)
        }
      }
    }

    let header = SyntaxNodeString(
      stringLiteral: String(
        format: "%@(\n%@\n)",
        group.isPublic ? "public init" : "init",
        rawHeaders.joined(separator: ",\n")
      )
    )
    let initDecl = try InitializerDeclSyntax(header) {
      for raw in rawBodies {
        ExprSyntax(stringLiteral: raw)
      }
    }
    return [DeclSyntax(initDecl)]
  }
}
