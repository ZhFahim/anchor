import type { Options } from "ky";
import { api } from "@/lib/api/client";
import { getRefreshToken } from "./store";
import type {
  ApiTokenResponse,
  AuthResponse,
  ChangePasswordCredentials,
  LoginCredentials,
  MagicLoginCode,
  OidcConfig,
  OidcExchangeResponse,
  RegisterCredentials,
  RegistrationMode,
  UpdateProfileDto,
  User,
} from "./types";

export async function login(
  credentials: LoginCredentials,
): Promise<AuthResponse> {
  return api.post("api/auth/login", { json: credentials }).json<AuthResponse>();
}

export async function register(
  credentials: RegisterCredentials,
): Promise<AuthResponse> {
  return api
    .post("api/auth/register", { json: credentials })
    .json<AuthResponse>();
}

export async function getMe(options?: Options): Promise<User> {
  return api.get("api/auth/me", options).json<User>();
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
    .post("api/auth/change-password", {
      // Keeps this session; the server signs out every other one.
      json: { ...credentials, refreshToken: getRefreshToken() ?? undefined },
    })
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

/** A one-time code that signs another device in as you. */
export async function createMagicLogin(): Promise<MagicLoginCode> {
  return api.post("api/auth/magic-login").json<MagicLoginCode>();
}

export async function redeemMagicLogin(code: string): Promise<AuthResponse> {
  return api
    .post("api/auth/magic-login/redeem", { json: { code } })
    .json<AuthResponse>();
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
