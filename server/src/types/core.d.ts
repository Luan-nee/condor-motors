import type { responseStatus } from '@/consts'
import type { Response } from 'express'

export type ResponseStatusType =
  (typeof responseStatus)[keyof typeof responseStatus]

export interface SendResponseArgs {
  res: Response
  message?: string
  data?: any
  pagination?: any
  metadata?: any
  status?: ResponseStatusType
  statusCode?: number
  error?: any
  cookie?: string
  authorization?: string
}

export type SuccessArgs = Pick<
  SendResponseArgs,
  | 'res'
  | 'message'
  | 'data'
  | 'pagination'
  | 'metadata'
  | 'cookie'
  | 'authorization'
>
export type CreatedArgs = Pick<SendResponseArgs, 'res' | 'message' | 'data'>
export type AcceptedArgs = Pick<SendResponseArgs, 'res' | 'message' | 'data'>
export type NoContentArgs = Pick<SendResponseArgs, 'res' | 'message'>
export type ErrorResponseArgs = Pick<SendResponseArgs, 'res' | 'error'>
