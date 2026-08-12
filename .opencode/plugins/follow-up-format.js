// follow-up-format OpenCode plugin
// Force-injects the fixed question format (FORMAT.md) into system context so
// the /follow-up-question question shape can never drift.
//
// The hook is `experimental.chat.system.transform`: it receives the array of
// system prompt strings in output.system. Appending FORMAT.md ensures the
// Q<n>(<area>) shape, the Recommended:/Caveats: lines, and the option rules
// are part of every session, whether or not the skill was loaded.
import { readFileSync } from "fs";
import { join } from "path";

export const FollowUpFormatPlugin = async ({ directory }) => {
  const formatPath = join(
    directory,
    ".opencode",
    "skills",
    "follow-up-question",
    "FORMAT.md",
  );

  let cached = null;
  const load = () => {
    if (cached !== null) return cached;
    try {
      cached = readFileSync(formatPath, "utf8");
    } catch {
      cached = "";
    }
    return cached;
  };

  return {
    "experimental.chat.system.transform": async (input, output) => {
      const format = load();
      if (format && !output.system.some((part) => part === format)) {
        output.system.push(format);
      }
    },
  };
};
