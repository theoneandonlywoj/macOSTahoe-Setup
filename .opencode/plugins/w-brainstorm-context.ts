import type { Plugin } from "@opencode-ai/plugin"

const BRAINSTORM_START = "[w-brainstorm:start]"
const TO_SPEC_START = "[w-to-spec:start]"
const QUESTION_PATTERN =
  /^Q(\d+) \[([a-z0-9]+(?:[.-][a-z0-9]+)*)\]\r?\nEvidence: ([^\r\n]*)\r?\nRecommendation: ([^\r\n]*)\r?\nQuestion: ([^\r\n]*)$/

type Message = {
  info: {
    role: string
    agent?: string
    sessionID?: string
  }
  parts: Array<Record<string, any>>
}

type Question = {
  id: string
  key: string
  evidence: string
  recommended: string
  question: string
  answer?: string
}

type BrainstormState = {
  v: 1
  topic: string
  lastQuestion: number
  decisions: Question[]
  pending?: Omit<Question, "answer">
}

function messageText(message: Message) {
  return message.parts
    .filter((part) => part.type === "text" && typeof part.text === "string" && !part.ignored)
    .map((part) => part.text)
    .join("\n")
    .trim()
}

function parseQuestion(text: string): Omit<Question, "answer"> | undefined {
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

function latestBrainstormStart(messages: Message[]) {
  for (let index = messages.length - 1; index >= 0; index--) {
    const message = messages[index]
    if (message.info.role !== "user" || message.info.agent !== "w-brainstorm") continue
    if (messageText(message).includes(BRAINSTORM_START)) return index
  }
  return -1
}

function buildState(messages: Message[], start: number): BrainstormState {
  const settled = new Map<string, Question>()
  let pending: Omit<Question, "answer"> | undefined
  let lastQuestion = 0

  for (let index = start + 1; index < messages.length; index++) {
    const message = messages[index]
    if (message.info.role !== "assistant" || message.info.agent !== "w-brainstorm") continue
    const question = parseQuestion(messageText(message))
    if (!question) continue

    lastQuestion = Math.max(lastQuestion, Number(question.id.slice(1)))
    let answer: string | undefined
    for (let next = index + 1; next < messages.length; next++) {
      const candidate = messages[next]
      if (candidate.info.role === "assistant" && parseQuestion(messageText(candidate))) break
      if (candidate.info.role !== "user") continue
      const text = messageText(candidate)
      if (text.includes(TO_SPEC_START) || text.includes(BRAINSTORM_START)) break
      if (candidate.info.agent === "w-brainstorm" && text) answer = text
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
  const topicDecision = settled.get("topic")?.answer
  return {
    v: 1,
    topic: topicArgument(startText) || topicDecision || "",
    lastQuestion,
    decisions: [...settled.values()],
    ...(pending ? { pending } : {}),
  }
}

function capsule(state: BrainstormState) {
  return `[w-brainstorm-context]\n${JSON.stringify(state)}\n[/w-brainstorm-context]`
}

function replaceUserText(message: Message, text: string): Message | undefined {
  let replaced = false
  const parts = message.parts.flatMap((part) => {
    if (part.type !== "text" || part.synthetic) return [part]
    if (replaced) return []
    replaced = true
    return [{ ...part, text }]
  })
  return replaced ? { ...message, parts } : undefined
}

export const BrainstormContextPlugin = (async () => {
  const capsuleBySession = new Map<string, string>()

  return {
    "experimental.chat.messages.transform": async (_input, output) => {
      try {
        const messages = output.messages as Message[]
        const start = latestBrainstormStart(messages)
        if (start < 0) return

        const latestUserIndex = messages.findLastIndex((message) => message.info.role === "user")
        if (latestUserIndex < 0) return
        const latestUser = messages[latestUserIndex]
        const activeAgent = latestUser.info.agent
        if (activeAgent !== "w-brainstorm" && activeAgent !== "w-to-spec") return

        const state = buildState(messages, start)
        const context = capsule(state)
        const sessionID = latestUser.info.sessionID
        if (sessionID) capsuleBySession.set(sessionID, context)

        const currentText = messageText(latestUser)
        const replacement =
          activeAgent === "w-to-spec"
            ? `${currentText}\n\n${context}`
            : `[w-brainstorm:continue]\n${context}\nAsk the next single question.`
        const compactUser = replaceUserText(latestUser, replacement)
        if (!compactUser) return

        output.messages.splice(
          0,
          output.messages.length,
          compactUser as (typeof output.messages)[number],
          ...output.messages.slice(latestUserIndex + 1),
        )
      } catch {
        // Context optimization must never prevent the underlying workflow from running.
      }
    },
    "experimental.session.compacting": async (input, output) => {
      const context = capsuleBySession.get(input.sessionID)
      if (context) output.context.push(`Preserve this brainstorm state exactly:\n${context}`)
    },
  }
}) satisfies Plugin
