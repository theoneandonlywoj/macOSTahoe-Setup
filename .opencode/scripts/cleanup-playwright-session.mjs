#!/usr/bin/env node

import { lstat, readdir, realpath, rm } from "node:fs/promises"
import path from "node:path"

const session = process.argv[2]
const validSession =
  typeof session === "string" &&
  session.length <= 64 &&
  /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(session)

if (!validSession) {
  console.error("Invalid Playwright session identifier")
  process.exitCode = 2
} else {
  try {
    const workspace = process.cwd()
    const root = path.resolve(workspace, ".playwright-cli")
    const target = path.resolve(root, `w-playwright-${session}`)

    if (path.dirname(target) !== root) {
      throw new Error("Resolved session path escaped the cleanup root")
    }

    let rootStat
    try {
      rootStat = await lstat(root)
    } catch (error) {
      if (error?.code === "ENOENT") {
        console.log("No Playwright session directory found")
        process.exit(0)
      }
      throw error
    }

    if (!rootStat.isDirectory() || rootStat.isSymbolicLink()) {
      throw new Error("Playwright cleanup root is not a real directory")
    }

    let targetStat
    try {
      targetStat = await lstat(target)
    } catch (error) {
      if (error?.code === "ENOENT") {
        console.log("No Playwright session directory found")
        process.exit(0)
      }
      throw error
    }

    if (!targetStat.isDirectory() || targetStat.isSymbolicLink()) {
      throw new Error("Playwright session path is not a real directory")
    }

    if ((await realpath(target)) !== target || path.dirname(await realpath(target)) !== await realpath(root)) {
      throw new Error("Playwright session path failed containment validation")
    }

    const rejectSymlinks = async (directory) => {
      for (const entry of await readdir(directory, { withFileTypes: true })) {
        const entryPath = path.join(directory, entry.name)
        const entryStat = await lstat(entryPath)
        if (entryStat.isSymbolicLink()) {
          throw new Error("Playwright session contains a symbolic link")
        }
        if (entryStat.isDirectory()) await rejectSymlinks(entryPath)
      }
    }

    await rejectSymlinks(target)
    await rm(target, { recursive: true })
    console.log(`Removed .playwright-cli/w-playwright-${session}`)
  } catch (error) {
    console.error(error instanceof Error ? error.message : "Playwright cleanup failed")
    process.exitCode = 1
  }
}
