export function requireOrThrow(key: string): any {
  if (process.env[key]) {
    return process.env[key];
  } else {
    throw new Error(`${key} is not defined`);
  }
}

export function assertBool(
  bool: Boolean,
  message: string | undefined = undefined,
) {
  let printMessage = message ? message : "Assertion failed";
  if (!bool) {
    throw new Error(printMessage);
  }
}
