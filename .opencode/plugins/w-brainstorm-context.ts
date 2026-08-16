import type { Hooks, Plugin } from "@opencode-ai/plugin"

const BRAINSTORM_START = "[w-brainstorm:start]"
const TO_SPEC_START = "[w-to-spec:start]"
const QUESTION_PATTERN =
  /^Q(\d+) \[([a-z0-9]+(?:[.-][a-z0-9]+)*)\]\r?\nEvidence: ([^\r\n]*)\r?\nRecommendation: ([^\r\n]*)\r?\nQuestion: ([^\r\n]*)$/

type TransformHook = NonNullable<Hooks["experimental.chat.messages.transform"]>
export type ChatMessage = Parameters<TransformHook>[1]["messages"][number]
type TextPart = Extract<ChatMessage["parts"][number], { type: "text" }>

export type Question = {
  id: string
  key: string
  evidence: string
  recommended: string
  question: string
  answer?: string
}

export type BrainstormState = {
  v: 1
  topic: string
  lastQuestion: number
  decisions: Question[]
  pending?: Omit<Question, "answer">
}

export function messageText(message: ChatMessage, includeSynthetic = true) {
  return message.parts
    .filter(
      (part): part is TextPart =>
        part.type === "text" &&
        !part.ignored &&
        (includeSynthetic || part.synthetic !== true),
    )
    .map((part) => part.text)
    .join("\n")
    .trim()
}

export function messageAgent(message: ChatMessage) {
  return message.info.role === "user" ? message.info.agent : message.info.mode
}

export function hasSyntheticControlLine(message: ChatMessage, marker: string) {
  return message.parts.some(
    (part) =>
      part.type === "text" &&
      part.synthetic === true &&
      part.text.split(/\r?\n/).some((line) => line === marker),
  )
}

export function parseQuestion(text: string): Omit<Question, "answer"> | undefined {
  const match = text.trim().match(QUESTION_PATTERN)
  if (!match) return
  return {
    id: `Q${match[1]}`,
    key: match[2],
    evidence: match[3],
    recommended: match[4],
    question: match[5],
  }
}

function topicArgument(text: string) {
  return text.match(/^Topic argument:[ \t]*([^\r\n]*)/m)?.[1]?.trim() ?? ""
}

export function latestBrainstormStart(messages: ChatMessage[]) {
  for (let index = messages.length - 1; index >= 0; index--) {
    const message = messages[index]
    if (message.info.role !== "user" || messageAgent(message) !== "w-brainstorm") continue
    if (hasSyntheticControlLine(message, BRAINSTORM_START)) return index
  }
  return -1
}

export function buildState(messages: ChatMessage[], start: number): BrainstormState {
  const settled = new Map<string, Question>()
  let pending: Omit<Question, "answer"> | undefined
  let lastQuestion = 0

  for (let index = start + 1; index < messages.length; index++) {
    const message = messages[index]
    if (message.info.role !== "assistant" || messageAgent(message) !== "w-brainstorm") continue
    const question = parseQuestion(messageText(message))
    if (!question) continue

    lastQuestion = Math.max(lastQuestion, Number(question.id.slice(1)))
    let answer: string | undefined
    for (let next = index + 1; next < messages.length; next++) {
      const candidate = messages[next]
      if (
        candidate.info.role === "assistant" &&
        messageAgent(candidate) === "w-brainstorm" &&
        parseQuestion(messageText(candidate))
      ) {
        break
      }
      if (candidate.info.role !== "user") continue
      if (
        hasSyntheticControlLine(candidate, TO_SPEC_START) ||
        hasSyntheticControlLine(candidate, BRAINSTORM_START)
      ) {
        break
      }
      const text = messageText(candidate, false)
      if (messageAgent(candidate) === "w-brainstorm" && text) answer = text
      break
    }

    if (answer === undefined) {
      pending = question
      continue
    }

    pending = undefined
    settled.delete(question.key)
    settled.set(question.key, { ...question, answer })
  }

  const startText = messageText(messages[start])
  return {
    v: 1,
    topic: topicArgument(startText) || settled.get("topic")?.answer || "",
    lastQuestion,
    decisions: [...settled.values()],
    ...(pending ? { pending } : {}),
  }
}

export function capsule(state: BrainstormState) {
  return `[w-brainstorm-context]\n${JSON.stringify(state)}\n[/w-brainstorm-context]`
}

export function replaceUserText(message: ChatMessage, text: string): ChatMessage | undefined {
  let replaced = false
  const parts = message.parts.flatMap((part) => {
    if (part.type !== "text" || part.synthetic) return [part]
    if (replaced) return []
    replaced = true
    return [{ ...part, text }]
  })
  return replaced ? { ...message, parts } : undefined
}

export function transformBrainstormMessages(messages: ChatMessage[]) {
  const start = latestBrainstormStart(messages)
  if (start < 0) return

  const latestUserIndex = messages.findLastIndex((message) => message.info.role === "user")
  if (latestUserIndex < 0) return
  const latestUser = messages[latestUserIndex]
  const activeAgent = messageAgent(latestUser)
  if (activeAgent !== "w-brainstorm" && activeAgent !== "w-to-spec") return

  const state = buildState(messages, start)
  const context = capsule(state)
  const currentText = messageText(latestUser)
  const replacement =
    activeAgent === "w-to-spec"
      ? `${currentText}\n\n${context}`
      : `[w-brainstorm:continue]\n${context}\nAsk the next single question.`
  const compactUser = replaceUserText(latestUser, replacement)
  if (!compactUser) return

  return {
    messages: [compactUser, ...messages.slice(latestUserIndex + 1)],
    context,
    sessionID: latestUser.info.sessionID,
  }
}

export function createBrainstormContextHooks(
  logError: (error: unknown) => Promise<void> = async () => {},
): Hooks {
  const capsuleBySession = new Map<string, string>()

  return {
    "experimental.chat.messages.transform": async (_input, output) => {
      try {
        const result = transformBrainstormMessages(output.messages)
        if (!result) return
        output.messages.splice(0, output.messages.length, ...result.messages)
        capsuleBySession.set(result.sessionID, result.context)
      } catch (error) {
        try {
          await logError(error)
        } catch {
          // Context optimization must fail open even when logging is unavailable.
        }
      }
    },
    event: async ({ event }) => {
      if (event.type === "session.deleted") capsuleBySession.delete(event.properties.info.id)
    },
    "experimental.session.compacting": async (input, output) => {
      const context = capsuleBySession.get(input.sessionID)
      if (context) output.context.push(`Preserve this brainstorm state exactly:\n${context}`)
    },
  }
}

export const BrainstormContextPlugin = (async ({ client }) =>
  createBrainstormContextHooks(async (error) => {
    await client.app.log({
      body: {
        service: "w-brainstorm-context",
        level: "error",
        message: "Failed to transform brainstorm context",
        extra: { error: error instanceof Error ? error.message : String(error) },
      },
    })
  })) satisfies Plugin
