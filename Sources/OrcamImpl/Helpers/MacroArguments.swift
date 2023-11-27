import Foundation
import MacroToolkit

public struct MacroArguments {
  private var arguments: [String: Expr] = [:]
  private var overridenArguments: [String: Any] = [:]

  public init(from macroAttribute: MacroAttribute, overriden overridenArguments: [String: Any] = [:]) {
    self.arguments = Dictionary(
      uniqueKeysWithValues: macroAttribute.arguments.compactMap { label, expr in
        label.map { ($0, expr) }
      }
    )
    self.overridenArguments = overridenArguments
  }

  public func value<T>(for label: String, default defaultValue: T) -> T {
    func withFallback(_ v: some Any) -> T {
      if let v = v as? T { return v }
      if let v = overridenArguments[label] as? T { return v }
      return defaultValue
    }

    let expr = self.arguments[label]
    switch defaultValue {
    case is Bool:
      return withFallback(expr?.asBooleanLiteral?.value)
    case is String:
      return withFallback(expr?.asStringLiteral?.value)
    case is Int:
      return withFallback(expr?.asIntegerLiteral?.value)
    case is Double, is Float:
      return withFallback(expr?.asFloatLiteral?.value)
    default:
      return withFallback(T?.none)
    }
  }
}
