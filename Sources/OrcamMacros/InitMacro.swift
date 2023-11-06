import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro: MemberMacro {
  enum MacroError: Error {
    case notAStructOrClass
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let storedProperties: [VariableDeclSyntax] = try {
      if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
        return classDeclaration.storedProperties()
      } else if let structDeclaration = declaration.as(StructDeclSyntax.self) {
        return structDeclaration.storedProperties()
      } else {
        throw MacroError.notAStructOrClass
      }
    }()

    let initArguments = storedProperties.compactMap { property -> (name: String, type: String, default: String?, isWrapped: Bool)? in
      guard let patternBinding = property.bindings.first?.as(PatternBindingSyntax.self),
            let name = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
            let type = patternBinding.typeAnnotation?.type
      else { return nil }
      var defaultValue: String?
      var typedDescription = type.trimmedDescription
      if type.is(FunctionTypeSyntax.self) {
        typedDescription = "@escaping \(typedDescription)"
      } else if type.is(OptionalTypeSyntax.self) || type.as(IdentifierTypeSyntax.self)?.name.text == "Optional" {
        defaultValue = "nil"
      }
      let isWrapped = ["@State", "@StateObject"].contains(property.attributes.trimmedDescription)
      return (name: name.text, type: typedDescription, default: defaultValue, isWrapped: isWrapped)
    }

    // TODO (thuyen): Detect `public`
    let isPublic = true
    let prefix = isPublic ? "public " : ""
    let initArgumentsDecl = initArguments
      .map { t -> String in
        let s = "\(t.name): \(t.type)"
        return t.default.map { "\(s) = \($0)" } ?? s
      }
      .joined(separator: ",\n")
    let initDeclSyntax = try InitializerDeclSyntax(
      SyntaxNodeString(stringLiteral: "\(prefix)init(\n\(initArgumentsDecl)\n)"),
      bodyBuilder: {
        for argument in initArguments {
          if argument.isWrapped {
            ExprSyntax(stringLiteral: "self._\(argument.name) = .init(wrappedValue: \(argument.name))")
          } else {
            ExprSyntax(stringLiteral: "self.\(argument.name) = \(argument.name)")
          }
        }
      }
    )

    let finalDeclaration = DeclSyntax(initDeclSyntax)
    return [finalDeclaration]
  }
}

extension VariableDeclSyntax {
  var isStoredProperty: Bool {
    guard let binding = bindings.first,
          bindings.count == 1,
          !isLazyProperty,
          !isInitialized else {
      return false
    }
    guard let accessorBlock = binding.accessorBlock else { return true }
    switch accessorBlock.accessors {
    case .accessors(let node):
      for accessor in node {
        switch accessor.accessorSpecifier.tokenKind {
        case .keyword(Keyword.willSet), .keyword(Keyword.didSet):
          return true
        default:
          break
        }
      }
      return false
    case .getter:
      return false
    }
  }

  var isLazyProperty: Bool {
    modifiers.contains { $0.name.tokenKind == .keyword(Keyword.lazy) }
  }

  var isInitialized: Bool {
    bindings.first?.initializer != nil
  }
}

extension DeclGroupSyntax {
  func storedProperties() -> [VariableDeclSyntax] {
    memberBlock.members.compactMap { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self),
            variable.isStoredProperty else {
        return nil
      }

      return variable
    }
  }
}
