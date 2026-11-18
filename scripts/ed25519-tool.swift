// Ed25519 without the keychain, independent of Sparkle's own code.
//
//   ed25519-tool.swift keygen <folder>                     new keys: <folder>/private.key, <folder>/public.key
//   ed25519-tool.swift verify <public key> <signature> <file>   exit 0 when the signature is valid
//   ed25519-tool.swift public <private key file>           prints the public key of a private key file
//
// Keys are base64: the private one is the 32 byte seed, the format `generate_keys -x` writes and
// `sign_update --ed-key-file` reads. Used by make-update-key.sh and release.sh (same tool as in Mowa).
import CryptoKit
import Foundation

func fail(_ message: String, code: Int32 = 2) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

func decode(_ text: String, what: String) -> Data {
    guard let data = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { fail("\(what) is not base64") }
    return data
}

let arguments = Array(CommandLine.arguments.dropFirst())
switch arguments.first {
case "keygen" where arguments.count == 2:
    let folder = URL(fileURLWithPath: arguments[1], isDirectory: true)
    let key = Curve25519.Signing.PrivateKey()
    let privateFile = folder.appendingPathComponent("private.key")
    FileManager.default.createFile(atPath: privateFile.path, contents: nil, attributes: [.posixPermissions: 0o600])
    try Data(key.rawRepresentation.base64EncodedString().utf8).write(to: privateFile)
    try Data(key.publicKey.rawRepresentation.base64EncodedString().utf8).write(to: folder.appendingPathComponent("public.key"))
case "verify" where arguments.count == 4:
    let publicKey: Curve25519.Signing.PublicKey
    do {
        publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: decode(arguments[1], what: "The public key"))
    } catch {
        fail("Not an Ed25519 public key")
    }
    let file = try Data(contentsOf: URL(fileURLWithPath: arguments[3]), options: .mappedIfSafe)
    guard publicKey.isValidSignature(decode(arguments[2], what: "The signature"), for: file) else { fail("The signature does not match", code: 1) }
case "public" where arguments.count == 2:
    let text = try String(contentsOfFile: arguments[1], encoding: .utf8)
    do {
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: decode(text, what: "The private key"))
        print(key.publicKey.rawRepresentation.base64EncodedString())
    } catch {
        fail("Not a 32 byte Ed25519 private key")
    }
default:
    fail("usage: ed25519-tool.swift keygen <folder> | verify <public key> <signature> <file> | public <private key file>")
}
