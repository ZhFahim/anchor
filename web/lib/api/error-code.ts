import { HTTPError } from "ky";

type ErrorBody = {
  code?: string;
  params?: Record<string, string | number>;
  fields?: { field: string; rules: string[] }[];
};

const bodyOf = (error: unknown): ErrorBody =>
  error instanceof HTTPError &&
  typeof error.data === "object" &&
  error.data !== null
    ? (error.data as ErrorBody)
    : {};

/** The server's name for the error, from server/src/common/errors/error-code.ts. */
export const errorCodeOf = (error: unknown): string | undefined =>
  bodyOf(error).code;

export const errorParamsOf = (
  error: unknown,
): Record<string, string | number> => bodyOf(error).params ?? {};

export const refusedFieldsOf = (error: unknown): string[] =>
  bodyOf(error).fields?.map((field) => field.field) ?? [];
