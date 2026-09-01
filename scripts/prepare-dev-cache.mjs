import { createHash } from "node:crypto";
import { existsSync, lstatSync, mkdirSync, readlinkSync, renameSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, join, resolve } from "node:path";

const projectDir = process.cwd();
const isOneDriveWorkspace = process.platform === "win32" && projectDir.toLowerCase().includes("\\onedrive\\");

if (isOneDriveWorkspace) {
  const projectKey = createHash("sha256").update(projectDir.toLowerCase()).digest("hex").slice(0, 12);
  const localProjectRoot = join(process.env.LOCALAPPDATA || tmpdir(), "QuizForge", `${basename(projectDir)}-${projectKey}`);
  const cacheRoot = join(localProjectRoot, ".next");
  const localModules = join(localProjectRoot, "node_modules");
  const workspaceModules = join(projectDir, "node_modules");
  const workspaceCache = join(projectDir, ".next");
  mkdirSync(cacheRoot, { recursive: true });

  if (!existsSync(localModules)) {
    symlinkSync(workspaceModules, localModules, "junction");
    console.log(`[dev-cache] Linked local module resolution to ${workspaceModules}.`);
  }

  let correctlyLinked = false;
  if (existsSync(workspaceCache)) {
    try {
      correctlyLinked = lstatSync(workspaceCache).isSymbolicLink() && resolve(projectDir, readlinkSync(workspaceCache)) === resolve(cacheRoot);
    } catch {
      // OneDrive placeholders can throw EINVAL when Node attempts readlink.
    }
  }

  if (!correctlyLinked) {
    if (existsSync(workspaceCache)) {
      let staleCache = join(projectDir, ".next-onedrive-stale");
      if (existsSync(staleCache)) staleCache = `${staleCache}-${Date.now()}`;
      renameSync(workspaceCache, staleCache);
      console.log(`[dev-cache] Moved the OneDrive-managed cache to ${basename(staleCache)}.`);
    }
    symlinkSync(cacheRoot, workspaceCache, "junction");
    console.log(`[dev-cache] Linked .next to local cache: ${cacheRoot}`);
  }
}
