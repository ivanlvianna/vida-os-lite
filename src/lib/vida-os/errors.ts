export type VidaOsErrorCode =
  | 'AUTH_REQUIRED'
  | 'FORBIDDEN'
  | 'INVALID_INPUT'
  | 'DOMAIN_RPC_FAILED'
  | 'MISSING_SERVER_CONFIGURATION'

export class VidaOsError extends Error {
  readonly code: VidaOsErrorCode
  readonly causeValue?: unknown

  constructor(code: VidaOsErrorCode, message: string, causeValue?: unknown) {
    super(message)
    this.name = 'VidaOsError'
    this.code = code
    this.causeValue = causeValue
  }
}
