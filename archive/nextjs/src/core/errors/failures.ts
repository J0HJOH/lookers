// Application-level failures. Data-layer code converts technical errors into these;
// users only ever see `message`, never raw errors, status codes or SQL text.

export type FailureKind =
  | "validation"
  | "not_found"
  | "network"
  | "auth"
  | "forbidden"
  | "out_of_stock"
  | "external_service"
  | "server"
  | "unexpected"
  | "not_configured";

export interface Failure {
  kind: FailureKind;
  message: string;
}

export type Result<T> = { ok: true; value: T } | { ok: false; failure: Failure };

export const ok = <T>(value: T): Result<T> => ({ ok: true, value });
export const fail = <T = never>(kind: FailureKind, message: string): Result<T> => ({
  ok: false,
  failure: { kind, message },
});
