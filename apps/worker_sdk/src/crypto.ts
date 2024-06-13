import { sha256 } from "js-sha256";

function generateRandomString(length) {
  const characters = "abcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  for (let i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return result;
}

export function generateWorkerSalt(length: number = 16): string {
  if (length > 32) {
    throw new Error("Salt length must be less than or equal to 32");
  }

  return sha256
    .create()
    .update(generateRandomString(16))
    .hex()
    .substring(0, length);
}

export function generateWorkerID(key: string, salt: string) {
  return sha256
    .create()
    .update(key + salt)
    .hex();
}
