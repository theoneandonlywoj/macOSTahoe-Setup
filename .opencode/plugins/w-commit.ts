import { type Plugin, tool } from "@opencode-ai/plugin"

type Proposal = { message: string; files: string[] }
const proposals = new Map<string, Proposal>()

export const WCommitPlugin: Plugin = async ({ $ }) => {
  const run = async (args: string[]) => {
    const result = await $`git ${args}`.quiet().nothrow()
    return {
      code: result.exitCode,
      out: result.stdout.toString().trim(),
      err: result.stderr.toString().trim(),
    }
  }

  const stagedFiles = async (): Promise<string[]> => {
    const { code, out } = await run(["diff", "--cached", "--name-only"])
    if (code !== 0) throw new Error(`git diff --cached failed: ${out}`)
    return out.split("\n").filter(Boolean)
  }

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && /\bgit\s+commit\b/.test(output.args.command ?? "")) {
        throw new Error(
          "Direct `git commit` via bash is blocked. Use the w_commit_propose and w_commit_execute tools instead.",
        )
      }
    },

    tool: {
      w_commit_propose: tool({
        description:
          "Propose a commit message for the currently staged changes. Returns the structured proposal (files + message) that is shown to the user. Must be called before w_commit_execute.",
        args: {
          message: tool.schema
            .string()
            .describe("The proposed commit message in the repository's conventional style."),
        },
        async execute(args, ctx) {
          const files = await stagedFiles()
          if (files.length === 0) {
            return "Nothing is staged. Run `git add <file>` first, then call this tool again."
          }
          proposals.set(ctx.sessionID, { message: args.message, files })
          return [
            "Files:",
            ...files.map((file) => `- ${file}`),
            "",
            "",
            "Commit message:",
            args.message,
          ].join("\n")
        },
      }),

      w_commit_execute: tool({
        description:
          "Commit the staged changes with the exact message that was proposed and approved by the user. Any extra information the user provided is appended as the commit body.",
        args: {
          message: tool.schema
            .string()
            .describe("The exact message from the approved w_commit_propose proposal. Do not alter it."),
          extra: tool.schema
            .string()
            .optional()
            .describe("Optional extra information the user added during approval; appended as the commit body."),
        },
        async execute(args, ctx) {
          const proposal = proposals.get(ctx.sessionID)
          if (!proposal) {
            throw new Error("No active proposal. Call w_commit_propose first and wait for user approval.")
          }
          if (proposal.message !== args.message) {
            throw new Error("The message differs from the approved proposal. Do not change it.")
          }

          const files = await stagedFiles()
          if (files.join("\n") !== proposal.files.join("\n")) {
            throw new Error("Staged files changed since the proposal. Re-run w_commit_propose and get approval again.")
          }

          const name = (await run(["config", "user.name"])).out
          const email = (await run(["config", "user.email"])).out
          if (!name || !email) {
            throw new Error("git config user.name and user.email must be set before committing.")
          }
          const date = (await $`date +%Y-%m-%dT%H:%M:%S%z`.quiet().text()).trim()
          const author = `${name} <${email}>`
          const body = args.extra?.trim() ? `\n\n${args.extra.trim()}` : ""
          const fullMessage = args.message + body

          const result = await $`git commit -m ${fullMessage} --author=${author} --date=${date}`.quiet().nothrow()
          if (result.exitCode !== 0) {
            throw new Error(`git commit failed (exit ${result.exitCode}): ${result.stderr.toString().trim()}`)
          }

          proposals.delete(ctx.sessionID)
          const hash = (await $`git log -1 --format=%h`.quiet().text()).trim()
          return `Committed ${hash}:\n${fullMessage}`
        },
      }),
    },
  }
}