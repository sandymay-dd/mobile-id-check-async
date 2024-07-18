import { LogAttributes } from "@aws-lambda-powertools/logger/lib/cjs/types/Log";
import { Context } from "vm";
import { ILoggerAdapter } from "../logger";
import { LogMessage } from "../types";

export class MockLoggingAdapter<T extends string> implements ILoggerAdapter<T> {
  logMessages: { logMessage: LogMessage<T>; data: LogAttributes }[] = [];
  private contextBody: Context | undefined;
  private temporaryKeys: { [key in string]: string } | undefined;
  info = (logMessage: LogMessage<T>, data: LogAttributes): void => {
    const enrichedLogMessage = {
      ...this.contextBody,
      ...this.temporaryKeys,
      ...logMessage,
    };
    this.logMessages.push({ logMessage: enrichedLogMessage, data });
  };
  getLogMessages = (): { logMessage: LogMessage<T>; data: LogAttributes }[] => {
    return this.logMessages;
  };

  addContext = (lambdaContext: Context) => {
    this.contextBody = lambdaContext;
  };
  appendKeys = (keys: { authSessionId: string }) => {
    this.temporaryKeys = { ...keys };
  };
}
