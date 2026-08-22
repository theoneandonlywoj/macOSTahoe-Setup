import assert from "node:assert/strict"
import { access, mkdtemp, mkdir, symlink, writeFile } from "node:fs/promises"
import os from "node:os"
import path from "node:path"
import { spawnSync } from "node:child_process"
import test from "node:test"
import { fileURLToPath } from "node:url"

const helper = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../scripts/cleanup-playwright-session.mjs",
)

async function workspace() {
  return mkdtemp(path.join(os.tmpdir(), "opencode-playwright-cleanup-"))
}

function run(cwd, session) {
  return spawnSync(process.execPath, [helper, session], { cwd, encoding: "utf8" })
}

test("removes only the requested session directory", async () => {
  const cwd = await workspace()
  const target = path.join(cwd, ".playwright-cli/w-playwright-flow-abc123")
  const other = path.join(cwd, ".playwright-cli/w-playwright-other-def456")
  await mkdir(path.join(target, "nested"), { recursive: true })
  await mkdir(other, { recursive: true })
  await writeFile(path.join(target, "nested/snapshot.yml"), "snapshot")

  const result = run(cwd, "flow-abc123")

  assert.equal(result.status, 0, result.stderr)
  assert.equal(result.stdout.trim(), "Removed .playwright-cli/w-playwright-flow-abc123")
  await assert.rejects(access(target))
  await access(other)
})

test("succeeds when the session directory is missing", async () => {
  const cwd = await workspace()
  const result = run(cwd, "missing-abc123")

  assert.equal(result.status, 0)
  assert.equal(result.stdout.trim(), "No Playwright session directory found")
})

test("rejects invalid and traversal identifiers", async () => {
  const cwd = await workspace()

  for (const session of ["../escape", "Uppercase", "double--hyphen", "name/child", ""]) {
    const result = run(cwd, session)
    assert.equal(result.status, 2, session)
    assert.match(result.stderr, /Invalid Playwright session identifier/)
  }
})

test("rejects a symlinked session directory", async () => {
  const cwd = await workspace()
  const outside = path.join(cwd, "outside")
  const root = path.join(cwd, ".playwright-cli")
  await mkdir(outside)
  await mkdir(root)
  await writeFile(path.join(outside, "keep.txt"), "keep")
  await symlink(outside, path.join(root, "w-playwright-link-abc123"))

  const result = run(cwd, "link-abc123")

  assert.equal(result.status, 1)
  assert.match(result.stderr, /not a real directory/)
})

test("rejects symbolic links inside a session directory", async () => {
  const cwd = await workspace()
  const outside = path.join(cwd, "outside.txt")
  const target = path.join(cwd, ".playwright-cli/w-playwright-nested-abc123")
  await mkdir(target, { recursive: true })
  await writeFile(outside, "keep")
  await symlink(outside, path.join(target, "snapshot-link"))

  const result = run(cwd, "nested-abc123")

  assert.equal(result.status, 1)
  assert.match(result.stderr, /contains a symbolic link/)
})
