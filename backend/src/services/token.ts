import crypto from "node:crypto";

export function createExitToken() {
  return `SC-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
}

export function hashToken(token: string) {
  return crypto.createHash("sha256").update(token).digest("hex");
}
