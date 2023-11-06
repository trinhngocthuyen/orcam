@attached(member, names: named(init))
public macro Init(
  defaultForOptional: Bool = true
) = #externalMacro(module: "OrcamMacros", type: "InitMacro")
