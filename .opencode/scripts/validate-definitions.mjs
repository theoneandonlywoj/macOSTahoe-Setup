#!/usr/bin/env node

import assert from "node:assert/strict"
import { readdir, readFile } from "node:fs/promises"
import path from "node:path"
import { parseDocument } from "yaml"

const root = process.cwd()

async function markdownFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true })
  const files = []
  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name)
    if (entry.isDirectory()) files.push(...(await markdownFiles(entryPath)))
    if (entry.isFile() && entry.name.endsWith(".md")) files.push(entryPath)
  }
  return files.sort()
}

async function definition(file) {
  const source = await readFile(file, "utf8")
  const match = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/)
  assert.ok(match, `${path.relative(root, file)} has invalid frontmatter boundaries`)
  const document = parseDocument(match[1], { uniqueKeys: true })
  assert.deepEqual(
    document.errors.map((error) => error.message),
    [],
    `${path.relative(root, file)} has invalid YAML frontmatter`,
  )
  return { file, data: document.toJS(), body: match[2] }
}

const agents = await Promise.all(
  (await markdownFiles(path.join(root, "agents"))).map(definition),
)
const commands = await Promise.all(
  (await markdownFiles(path.join(root, "commands"))).map(definition),
)
const skills = await Promise.all(
  (await markdownFiles(path.join(root, "skills"))).map(definition),
)

assert.equal(agents.length, 8, "expected eight workflow agents")
assert.equal(commands.length, 8, "expected eight workflow commands")
assert.equal(skills.length, 8, "expected eight workflow skills")

const agentsByName = new Map(agents.map((entry) => [entry.data.name, entry]))
const skillsByName = new Map(skills.map((entry) => [entry.data.name, entry]))
const expectedSubtask = new Map([
  ["w-brainstorm", false],
  ["w-to-spec", false],
  ["w-implement", true],
  ["w-research", true],
  ["w-commit", true],
  ["w-into-commits", true],
  ["w-elixir-update-deps", false],
  ["w-playwright-gen-test", false],
])

for (const [name, agent] of agentsByName) {
  assert.match(name, /^w-[a-z0-9]+(?:-[a-z0-9]+)*$/, `${name} is not a valid agent name`)
  assert.equal(agent.data.mode, "subagent", `${name} must be a subagent`)
  assert.equal(agent.data.hidden, true, `${name} must remain hidden`)
  assert.match(agent.data.description, new RegExp(`/${name}`), `${name} description must name its command`)
  assert.ok(agent.body.includes(`Use only through \`/${name}\``), `${name} must be command-only`)
  assert.equal(agent.data.permission?.read?.["*.env"], "deny", `${name} must deny *.env`)
  assert.equal(agent.data.permission?.read?.["*.env.*"], "deny", `${name} must deny *.env.*`)
  assert.equal(agent.data.permission?.external_directory, "deny", `${name} must deny external paths`)
  assert.equal(agent.data.permission?.skill?.[name], "allow", `${name} must allow only its skill`)
  assert.ok(skillsByName.has(name), `${name} has no matching skill`)
}

for (const command of commands) {
  const name = path.basename(command.file, ".md")
  assert.equal(command.data.agent, name, `${name} must route to its matching agent`)
  assert.ok(agentsByName.has(command.data.agent), `${name} references a missing agent`)
  assert.equal(command.data.subtask, expectedSubtask.get(name), `${name} has the wrong session mode`)
  assert.equal(typeof command.data.description, "string", `${name} needs a description`)
}

assert.equal(
  agentsByName.get("w-implement").data.permission.edit[".opencode/agents/w-implement.md"],
  "deny",
  "w-implement must not edit its own permissions",
)
assert.equal(
  agentsByName.get("w-elixir-update-deps").data.permission.edit[".opencode/**"],
  "deny",
  "w-elixir-update-deps must not persist shell approvals in project configuration",
)

for (const skill of skills) {
  const directoryName = path.basename(path.dirname(skill.file))
  assert.equal(skill.data.name, directoryName, `${directoryName} skill name must match its directory`)
  assert.match(skill.data.description, new RegExp(`/${directoryName}`), `${directoryName} skill must name its command`)
}

console.log("Validated eight command-agent-skill workflows")
