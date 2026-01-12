import { api } from "@/lib/api/client";
import type { AuthResponse, LoginCredentials, RegisterCredentials, ChangePasswordCredentials, User } from "./types";

export async function login(credentials: LoginCredentials): Promise<AuthResponse> {
  return api.post("api/auth/login", { json: credentials }).json<AuthResponse>();
}

export async function register(credentials: RegisterCredentials): Promise<AuthResponse> {
  return api.post("api/auth/register", { json: credentials }).json<AuthResponse>();
}

export async function getMe(): Promise<User> {
  return api.get("api/auth/me").json<User>();
}

export async function getRegistrationMode(): Promise<{ mode: "disabled" | "enabled" | "review" }> {
  return api.get("api/auth/registration-mode").json<{ mode: "disabled" | "enabled" | "review" }>();
}

export async function changePassword(credentials: ChangePasswordCredentials): Promise<{ message: string }> {
  return api.post("api/auth/change-password", { json: credentials }).json<{ message: string }>();
}
