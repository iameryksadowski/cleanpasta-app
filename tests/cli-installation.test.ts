import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

test('audit: CLI installation preserves unrelated files and links, repairs its own dangling link', () => {
  const dir = mkdtempSync(join(tmpdir(), 'cp-install-test-'));
  try {
    const harness = join(dir, 'main.swift');
    writeFileSync(harness, `
import Foundation
let fm = FileManager.default
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let helper = root.appendingPathComponent("Cleanpasta.app/Contents/Helpers/cleanpasta")
try fm.createDirectory(at: helper.deletingLastPathComponent(), withIntermediateDirectories: true)
try Data("helper".utf8).write(to: helper)
try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helper.path)
let folder = root.appendingPathComponent("bin")
try fm.createDirectory(at: folder, withIntermediateDirectories: true)
let link = folder.appendingPathComponent("cleanpasta")
try Data("other tool".utf8).write(to: link)
do { try CLIInstallation.install(helper: helper, folder: folder); fatalError("overwrote unrelated file") } catch {}
precondition(try! String(contentsOf: link) == "other tool")
try fm.removeItem(at: link)
try fm.createSymbolicLink(atPath: link.path, withDestinationPath: "/other/tool")
do { try CLIInstallation.install(helper: helper, folder: folder); fatalError("overwrote unrelated link") } catch {}
precondition(try! fm.destinationOfSymbolicLink(atPath: link.path) == "/other/tool")
try fm.removeItem(at: link)
// A link into another copy of Cleanpasta is ours to replace.
try fm.createSymbolicLink(atPath: link.path, withDestinationPath: root.appendingPathComponent("old/Cleanpasta.app/Contents/Helpers/cleanpasta").path)
try CLIInstallation.install(helper: helper, folder: folder)
precondition(try! fm.destinationOfSymbolicLink(atPath: link.path) == helper.path)
try CLIInstallation.install(helper: helper, folder: folder)
// 1.2.0: a link from 1.1.x moves to ~/.local/bin; the old one goes only once the shell finds the new folder.
let localBin = root.appendingPathComponent("home/.local/bin")
let elsewhere = root.appendingPathComponent("elsewhere")
try fm.createDirectory(at: elsewhere, withIntermediateDirectories: true)
try fm.createSymbolicLink(atPath: elsewhere.appendingPathComponent("cleanpasta").path, withDestinationPath: "/other/tool")
var left = try CLIInstallation.moveToLocalBin(previousFolders: [folder, elsewhere], helper: helper, localBin: localBin, removeOld: false)
precondition(left == [link], "only our link is a candidate")
precondition(try! fm.destinationOfSymbolicLink(atPath: localBin.appendingPathComponent("cleanpasta").path) == helper.path)
precondition((try? fm.destinationOfSymbolicLink(atPath: link.path)) != nil, "old link kept while ~/.local/bin is not on PATH")
left = try CLIInstallation.moveToLocalBin(previousFolders: [folder, elsewhere], helper: helper, localBin: localBin, removeOld: true)
precondition(left.isEmpty && (try? fm.destinationOfSymbolicLink(atPath: link.path)) == nil)
precondition(try! fm.destinationOfSymbolicLink(atPath: elsewhere.appendingPathComponent("cleanpasta").path) == "/other/tool")
precondition(try! CLIInstallation.moveToLocalBin(previousFolders: [folder], helper: helper, localBin: localBin, removeOld: true).isEmpty)
let home = root.appendingPathComponent("home")
precondition(!CLIInstallation.isOnShellPath(localBin, home: home, environmentPath: "/usr/bin:/bin"))
precondition(CLIInstallation.isOnShellPath(localBin, home: home, environmentPath: "/usr/bin:" + localBin.path))
try Data("# export PATH=$HOME/.local/bin:$PATH\\n".utf8).write(to: home.appendingPathComponent(".zshrc"))
precondition(!CLIInstallation.isOnShellPath(localBin, home: home, environmentPath: ""), "a comment does not count")
try Data("export PATH=\\"$HOME/.local/bin:$PATH\\"\\n".utf8).write(to: home.appendingPathComponent(".zprofile"))
precondition(CLIInstallation.isOnShellPath(localBin, home: home, environmentPath: ""))
`);
    const binary = join(dir, 'test-install');
    execFileSync('xcrun', ['swiftc', '-module-cache-path', process.env.CLANG_MODULE_CACHE_PATH ?? join(dir, 'cache'), 'Sources/CleanpastaCore/CLIInstallation.swift', harness, '-o', binary], { timeout: 180000 });
    execFileSync(binary, [dir], { timeout: 10000 });
  } finally { rmSync(dir, { recursive: true }); }
});
