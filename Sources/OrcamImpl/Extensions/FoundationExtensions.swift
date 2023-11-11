import Foundation

func zip<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
  if let a, let b { return (a, b) }
  return nil
}
