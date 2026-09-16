import assert from "node:assert/strict"
import test from "node:test"

import {
  buildState,
  createBrainstormContextHooks,
  latestBrainstormStart,
  messageText,
  transformBrainstormMessages,
  type ChatMessage,
} from "../plugins/w-brainstorm-context.ts"

let nextID = 0

function user(agent: string, text: string, synthetic = false): ChatMessage {
  const id = `message-${++nextID}`
  return {
    info: {
      id,
      sessionID: "session-1",
      role: "user",
      time: { created: nextID },
      agent,
      model: { providerID: "test", modelID: "test" },
    },
    parts: [
      {
        id: `part-${nextID}`,
        sessionID: "session-1",
        messageID: id,
        type: "text",
        text,
        synthetic,
      },
    ],
  }
}

function assistant(text: string): ChatMessage {
  const id = `message-${++nextID}`
  return {
    info: {
      id,
      sessionID: "session-1",
      role: "assistant",
      time: { created: nextID },
      parentID: "parent",
      modelID: "test",
      providerID: "test",
      mode: "w-brainstorm",
      path: { cwd: "/tmp", root: "/tmp" },
      cost: 0,
      tokens: { input: 0, output: 0, reasoning: 0, cache: { read: 0, write: 0 } },
    },
    parts: [
      {
        id: `part-${nextID}`,
        sessionID: "session-1",
        messageID: id,
        type: "text",
        text,
      },
    ],
  }
}

function command(agent: string, marker: string, argument: string) {
  const message = user(agent, marker, true)
  const id = message.info.id
  message.parts.push({
    id: `part-${++nextID}`,
    sessionID: "session-1",
    messageID: id,
    type: "text",
    text: argument,
  })
  return message
}

function question(number: number, key: string) {
  return assistant(
    `Q${number} [${key}]\nEvidence: Evidence ${number}\nRecommendation: Default ${number}\nQuestion: Question ${number}?`,
  )
}

test("replaces repeated decision keys with the latest answer", () => {
  const messages = [
    command("w-brainstorm", "[w-brainstorm:start]", "Topic argument: caching"),
    question(1, "scope"),
    user("w-brainstorm", "first"),
    question(2, "scope"),
    user("w-brainstorm", "second"),
  ]

  const state = buildState(messages, 0)
  assert.equal(state.decisions.length, 1)
  assert.equal(state.decisions[0].answer, "second")
  assert.equal(state.lastQuestion, 2)
})

test("keeps the latest unanswered question pending", () => {
  const messages = [
    command("w-brainstorm", "[w-brainstorm:start]", "Topic argument: caching"),
    question(1, "scope"),
  ]

  assert.equal(buildState(messages, 0).pending?.key, "scope")
})

test("ignores malformed question blocks", () => {
  const messages = [
    command("w-brainstorm", "[w-brainstorm:start]", "Topic argument: caching"),
    assistant("Q1 [scope]\nQuestion: missing required fields"),
    user("w-brainstorm", "answer"),
  ]

  const state = buildState(messages, 0)
  assert.equal(state.lastQuestion, 0)
  assert.deepEqual(state.decisions, [])
})

test("uses the topic decision when the command topic is empty", () => {
  const messages = [
    command("w-brainstorm", "[w-brainstorm:start]", "Topic argument: "),
    question(1, "topic"),
    user("w-brainstorm", "cache invalidation"),
  ]

  assert.equal(buildState(messages, 0).topic, "cache invalidation")
})

test("does not treat marker-looking normal answers as control lines", () => {
  const start = command("w-brainstorm", "[w-brainstorm:start]", "Topic argument: caching")
  const collision = user(
    "w-brainstorm",
    "Keep these literal examples: [w-brainstorm:start] and [w-to-spec:start]",
  )
  const messages = [start, question(1, "markers"), collision]

  assert.equal(latestBrainstormStart(messages), 0)
  assert.equal(buildState(messages, 0).decisions[0].answer, messageText(collision))
})

test("injects compact context into the w-to-spec command", () => {
  const messages = [
    command("w-brainstorm", "[w-brainstorm:start]", "Topic argument: caching"),
    question(1, "scope"),
    user("w-brainstorm", "memory only"),
    command("w-to-spec", "[w-to-spec:start]", "Target argument: "),
  ]

  const result = transformBrainstormMessages(messages)
  assert.ok(result)
  assert.equal(result.messages.length, 1)
  const text = result.messages[0].parts
    .filter(
      (part): part is Extract<(typeof result.messages)[number]["parts"][number], { type: "text" }> =>
        part.type === "text" && !part.synthetic,
    )
    .map((part) => part.text)
    .join("\n")
  assert.match(text, /\[w-brainstorm-context\]/)
  assert.match(text, /"scope"/)
  assert.match(text, /"memory only"/)
})

test("removes compact state when the session is deleted", async () => {
  const hooks = createBrainstormContextHooks()
  const output = {
    messages: [
      command("w-brainstorm", "[w-brainstorm:start]", "Topic argument: caching"),
      question(1, "scope"),
      user("w-brainstorm", "memory only"),
    ],
  }
  await hooks["experimental.chat.messages.transform"]?.({}, output)

  const before = { context: [] as string[] }
  await hooks["experimental.session.compacting"]?.({ sessionID: "session-1" }, before)
  assert.equal(before.context.length, 1)

  await hooks.event?.({
    event: { type: "session.deleted", properties: { info: { id: "session-1" } } } as never,
  })
  const after = { context: [] as string[] }
  await hooks["experimental.session.compacting"]?.({ sessionID: "session-1" }, after)
  assert.equal(after.context.length, 0)
})
