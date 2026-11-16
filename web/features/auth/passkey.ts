import {
  browserSupportsWebAuthn,
  startAuthentication,
  startRegistration,
} from "@simplewebauthn/browser";
import {
  enrollPasskeyOptions,
  enrollPasskeyVerify,
  getPasskeyLoginOptions,
  getPasskeyRegisterOptions,
  verifyPasskeyLogin,
  verifyPasskeyRegister,
} from "./api";
import type { PasskeySummary, Session } from "./types";

/** False where the browser can’t make or use a passkey at all. */
export function canUsePasskeys(): boolean {
  return typeof window !== "undefined" && browserSupportsWebAuthn();
}

/** Signs in with a passkey: no email and no password. */
export async function signInWithPasskey(): Promise<Session> {
  const { challenge, options } = await getPasskeyLoginOptions();
  const response = await startAuthentication({ optionsJSON: options });
  return verifyPasskeyLogin({ challenge, response });
}

/** Adds a passkey to the signed-in account. */
export async function addPasskey(name: string): Promise<PasskeySummary> {
  const { challenge, options } = await getPasskeyRegisterOptions();
  const response = await startRegistration({ optionsJSON: options });
  const { passkey } = await verifyPasskeyRegister({
    challenge,
    response,
    name,
  });
  return passkey;
}

/** Sets up a passkey as the second step before there is a session. */
export async function enrollPasskey(
  challenge: string,
  name?: string,
): Promise<Session> {
  const { options } = await enrollPasskeyOptions(challenge);
  const response = await startRegistration({ optionsJSON: options });
  return enrollPasskeyVerify({ challenge, response, name });
}
