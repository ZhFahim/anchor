import type {
  AuthenticationResponseJSON,
  PublicKeyCredentialCreationOptionsJSON,
  PublicKeyCredentialRequestOptionsJSON,
  RegistrationResponseJSON,
} from "@simplewebauthn/browser";
import { api } from "@/lib/api/client";
import type {
  ApiTokenResponse,
  AuthResponse,
  Capabilities,
  ChangePasswordCredentials,
  LoginCredentials,
  OidcConfig,
  OidcExchangeResponse,
  PasskeySummary,
  RegisterCredentials,
  RegisterOutcome,
  RegistrationMode,
  Session,
  SignInOutcome,
  Tokens,
  TotpEnabled,
  TotpSetup,
  TwoFactorLoginDto,
  TwoFactorStatus,
  UpdateProfileDto,
  User,
} from "./types";
import { registerOutcome, signInChallengeOf } from "./utils/two-factor";

/** A sign-in is a session, or a challenge: one more step to take first. */
export async function login(
  credentials: LoginCredentials,
): Promise<SignInOutcome> {
  try {
    const body = await api
      .post("api/auth/login", { json: credentials })
      .json<AuthResponse>();
    if (!body.access_token || !body.refresh_token)
      throw new Error("The server sent no session");
    return {
      kind: "signedIn",
      session: {
        access_token: body.access_token,
        refresh_token: body.refresh_token,
        user: body.user,
      },
    };
  } catch (error) {
    const challenge = signInChallengeOf(error);
    if (challenge) return challenge;
    throw error;
  }
}

export async function register(
  credentials: RegisterCredentials,
): Promise<RegisterOutcome> {
  const body = await api
    .post("api/auth/register", { json: credentials })
    .json<Parameters<typeof registerOutcome>[0]>();
  return registerOutcome(body);
}

export async function getCapabilities(): Promise<Capabilities> {
  return api.get("api/auth/capabilities").json<Capabilities>();
}

export async function loginWithTwoFactor(
  dto: TwoFactorLoginDto,
): Promise<Session> {
  return api.post("api/auth/login/2fa", { json: dto }).json<Session>();
}

export async function getPasskeyLoginOptions(): Promise<{
  challenge: string;
  options: PublicKeyCredentialRequestOptionsJSON;
}> {
  return api.post("api/auth/passkeys/login/options").json();
}

export async function verifyPasskeyLogin(dto: {
  challenge: string;
  response: AuthenticationResponseJSON;
}): Promise<Session> {
  return api.post("api/auth/passkeys/login/verify", { json: dto }).json();
}

/* Enrolment: a person the policy sends to set up a second step before they
   have a session. The challenge stands in for the bearer token. */

export async function enrollTotpSetup(challenge: string): Promise<TotpSetup> {
  return api
    .post("api/auth/enroll/totp/setup", { json: { challenge } })
    .json<TotpSetup>();
}

export async function enrollTotpEnable(dto: {
  challenge: string;
  code: string;
}): Promise<TotpEnabled & { user: User }> {
  return api
    .post("api/auth/enroll/totp/enable", { json: dto })
    .json<TotpEnabled & { user: User }>();
}

export async function enrollPasskeyOptions(
  challenge: string,
): Promise<{ options: PublicKeyCredentialCreationOptionsJSON }> {
  return api
    .post("api/auth/enroll/passkey/options", { json: { challenge } })
    .json();
}

export async function enrollPasskeyVerify(dto: {
  challenge: string;
  response: RegistrationResponseJSON;
  name?: string;
}): Promise<Session> {
  return api.post("api/auth/enroll/passkey/verify", { json: dto }).json();
}

/* Settings → Security */

export async function getTwoFactorStatus(): Promise<TwoFactorStatus> {
  return api.get("api/auth/2fa").json<TwoFactorStatus>();
}

/** A code is needed only to replace an authenticator that is already on. */
export async function setupTotp(
  current: { code?: string; recoveryCode?: string } = {},
): Promise<TotpSetup> {
  return api.post("api/auth/2fa/setup", { json: current }).json<TotpSetup>();
}

export async function enableTotp(
  code: string,
): Promise<Tokens & { recoveryCodes: string[] }> {
  return api.post("api/auth/2fa/enable", { json: { code } }).json();
}

export async function disableTotp(dto: {
  password: string;
  code?: string;
  recoveryCode?: string;
}): Promise<{ message: string }> {
  return api.post("api/auth/2fa/disable", { json: dto }).json();
}

export async function regenerateRecoveryCodes(dto: {
  password: string;
  code: string;
}): Promise<{ recoveryCodes: string[] }> {
  return api.post("api/auth/2fa/recovery-codes", { json: dto }).json();
}

export async function getPasskeyRegisterOptions(): Promise<{
  challenge: string;
  options: PublicKeyCredentialCreationOptionsJSON;
}> {
  return api.post("api/auth/passkeys/register/options").json();
}

export async function verifyPasskeyRegister(dto: {
  challenge: string;
  response: RegistrationResponseJSON;
  name: string;
}): Promise<{ passkey: PasskeySummary }> {
  return api.post("api/auth/passkeys/register/verify", { json: dto }).json();
}

export async function renamePasskey(
  id: string,
  name: string,
): Promise<{ passkey: PasskeySummary }> {
  return api
    .patch(`api/auth/passkeys/${encodeURIComponent(id)}`, { json: { name } })
    .json();
}

export async function deletePasskey(id: string): Promise<{ message: string }> {
  return api.delete(`api/auth/passkeys/${encodeURIComponent(id)}`).json();
}

export async function getMe(): Promise<User> {
  return api.get("api/auth/me").json<User>();
}

export async function getRegistrationMode(): Promise<{
  mode: RegistrationMode;
}> {
  return api
    .get("api/auth/registration-mode")
    .json<{ mode: RegistrationMode }>();
}

export async function changePassword(
  credentials: ChangePasswordCredentials,
): Promise<{ message: string }> {
  return api
    .post("api/auth/change-password", { json: credentials })
    .json<{ message: string }>();
}

export async function updateProfile(data: UpdateProfileDto): Promise<User> {
  return api.patch("api/auth/profile", { json: data }).json<User>();
}

export async function uploadProfileImage(imageFile: File): Promise<User> {
  const formData = new FormData();
  formData.append("image", imageFile);
  return api.post("api/auth/profile/image", { body: formData }).json<User>();
}

export async function removeProfileImage(): Promise<User> {
  return api.delete("api/auth/profile/image").json<User>();
}

export async function getApiToken(): Promise<ApiTokenResponse> {
  return api.get("api/auth/api-token").json<ApiTokenResponse>();
}

export async function regenerateApiToken(): Promise<ApiTokenResponse> {
  return api.post("api/auth/api-token/regenerate").json<ApiTokenResponse>();
}

export async function revokeApiToken(): Promise<ApiTokenResponse> {
  return api.delete("api/auth/api-token").json<ApiTokenResponse>();
}

export async function getOidcConfig(): Promise<OidcConfig> {
  return api.get("api/auth/oidc/config").json<OidcConfig>();
}

export async function exchangeOidcCode(
  code: string,
): Promise<OidcExchangeResponse> {
  return api
    .post("api/auth/oidc/exchange", { json: { code } })
    .json<OidcExchangeResponse>();
}

export async function revokeRefreshToken(
  refreshToken?: string | null,
): Promise<void> {
  if (!refreshToken) return;
  return api.post("api/auth/logout", { json: { refreshToken } }).json<void>();
}
